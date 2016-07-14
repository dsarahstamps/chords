class InstrumentsController < ApplicationController  
  before_action :set_instrument, only: [:show, :edit, :update, :destroy]

 # GET /instruments/1/live?var=varshortname&after=time
 # Return measurements and metadata for a given instrument, var and time period.
 # Limit the number of points returned to the instrument's display_points value.
  def live
    # Authorize access to the measurements
    authorize! :view, Measurement
 
    # Initialze the return value
    livedata = {
      :points         => [], 
      :display_points => 0,
      :refresh_msecs  => 1000
      }

    # Verify the parameters
    if params[:id] && params[:var] && params[:after]
    
      # Get the instrument
      our_instrument = Instrument.find(params[:id])
      
      # Fetch the data
      if our_instrument
      
        display_points            = our_instrument.display_points
        livedata[:display_points] = display_points
        refresh_rate_ms           = our_instrument.sample_rate_seconds*1000
        # Limit the chart refresh rate
        if (refresh_rate_ms < 1000) 
          refresh_rate_ms = 1000
        end
        livedata[:refresh_msecs]  = refresh_rate_ms
        
        # Get the measurements
        our_measurements = Measurement.where("instrument_id = ? and parameter = ?", params[:id], params[:var]).last(display_points)
        if our_measurements

          # Collect the times and values for the measurements
          points = []
          our_measurements.each {|x| points.append(x.mstime_and_value)}
          livedata[:points] = points
        end
      end
    end
    
    
    # Convert to JSON
    livedata_json = ActiveSupport::JSON.encode(livedata)
    
    # Return result
    render :json => livedata_json
  end
  
  # GET instruments/simulator
  def simulator
    authorize! :manage, Instrument
  
    # Returns:
    #  @instruments
    #  @sites

    @instruments = Instrument.all
    @sites       = Site.all
  end
  
  # GET /instruments/duplicate?instrument_id=1
  def duplicate

    # Does it exist?
    if Instrument.exists?(params[:instrument_id])

      old_instrument = Instrument.find(params[:instrument_id])

      authorize! :manage, old_instrument
            
      # Make a copy
      new_instrument = old_instrument.dup
      
      # Add"clone" to the name
      if !new_instrument.name.include? "clone" 
        new_instrument.name = new_instrument.name + " clone"
      end
      
      # Zero out the last url
      new_instrument.last_url = nil
  
      # Create duplicates of the vars
      old_instrument.vars.each do |v|
        new_var = v.dup
        new_var.save
        new_instrument.vars << new_var
      end
      
      # Save the new instrument
      new_instrument.save
    end
    
    redirect_to instruments_path
  end
  
  # GET /instruments
  # GET /instruments.json
  def index
    authorize! :view, Instrument

    @instruments = Instrument.all
    @sites = Site.all


  end

  # GET /instruments/1
  # GET /instruments/1.csv
  # GET /instruments/1.jsf
  # GET /instruments/1.json
  def show
    # This method sets the following instance variables:
    #  @params
    #  @varnames       - A hash of variable names for the instrument, keyed by the shortname
    #  @varshortname   - the shortname of the selected variable. Use it to get the full variable name from @varnames
    #  @units          - the units of the selected variable
    #  @tz_name        - the timezone name
    #  @tz_offset_mins - the timezone offset, in minutes
    #  @last_url       - the last url

    authorize! :view, Instrument

    
    # Determine and sanitize the last_url
    @last_url = ''
    if @instrument.last_url
      @last_url = InstrumentsHelper.sanitize_url(
        !@profile.secure_administration, 
        !(current_user && (can? :manage, Measurement)), 
        @instrument.last_url
        )
    end

    @params = params.slice(:start, :end)

    # Get the instrument and variable identifiers.
    instrument_name = @instrument.name
    site_name       = @instrument.site.name
    varshortnames   = Var.all.where("instrument_id = ?", @instrument.id).pluck(:shortname)
    project         = Profile.first.project
    affiliation     = Profile.first.affiliation
    metadata = [
      ["Project", project], 
      ["Site", site_name], 
      ["Affiliation", affiliation], 
      ["Instrument", instrument_name]
    ]

    # Get the timezone name and offset in minutes from UTC.
    @tz_name, @tz_offset_mins = ProfileHelper::tz_name_and_tz_offset
    
    # File name root
    file_root = "#{project}_#{site_name}_#{instrument_name}"
    file_root = file_root.split.join
     
    # Create a hash, with shortname => name
    @varnames = {}
    varshortnames.each do |vshort|
      @varnames[vshort] = Var.all.where("instrument_id = ? and shortname = ?", @instrument.id, vshort).pluck(:name)[0]
    end

    # Specify the selected variable shortname
    if params[:var]
      if varshortnames.include? params[:var]
        @varshortname  = params[:var]
      end
    else
      # the var parameter was not supplied, so select the first variable
      if @varnames.count > 0
        @varshortname = @varnames.first[0]
      end
    end

    # get the units
    @units = Var.all.where("instrument_id = ? and shortname = ?", @instrument.id, @varshortname).pluck(:units)[0]
        
    # Determine the time range
    # Default to the most recent day
    endtime   = Time.now
    starttime = endtime - 1.day

    if params.key?(:last)
      m = Measurement.where("instrument_id=?", params[:id]).order(measured_at: :desc).first
      starttime = m.measured_at
      endtime   = starttime
    else
      # if we have the start and end parameters
      if params.key?(:start)
        starttime = Time.parse(params[:start])
      else
        first_measurement = Measurement.where("instrument_id=?", params[:id]).order(measured_at: :desc).first
        
        if first_measurement
          starttime = first_measurement.measured_at
        end
      end

      if params.key?(:end)
        endtime = Time.parse(params[:end])
      else
        last_measurement = Measurement.where("instrument_id=?", params[:id]).order(measured_at: :desc).last
        
        if last_measurement
          endtime = last_measurement.measured_at
        end
      end
    end


    logger.debug(endtime)
    logger.debug(starttime)


    # get the measurements
    if params.key?(:last)
      # if 'last' was specified, use the exact time.
      measurements =  @instrument.measurements.where("measured_at = ?", starttime)
    else
      # otherwise, everything from the start time to less than the endtime.
      measurements =  @instrument.measurements.where("measured_at >= ? and measured_at < ?", starttime, endtime)
    end
    
    
measurements = Measurement.where("instrument_id=?", params[:id]).order(measured_at: :desc)


      logger.debug(measurements)    


    respond_to do |format|
      format.html

      format.sensorml {
        render :file => "app/views/instruments/sensorml.xml.haml", :layout => false
      }

      format.csv { 
        authorize! :download, @instrument
        
        send_data measurements.to_csv(metadata, @varnames),
          filename: file_root+'.csv' 
      }
      format.xml { 
        authorize! :download, @instrument

        send_data measurements.to_xml, filename: file_root+'.xml'
      }    
      format.json { 
        authorize! :download, @instrument

        # Convert metadata to a hash
        mdata = {}
        metadata.each do |m|
          mdata[m[0]] = m[1]
        end
        logger.debug(m)


        render json: measurements.columns_with_metadata(@varnames, mdata)
      }
      
      format.jsf { 
        authorize! :download, @instrument

        # Convert metadata to a hash
        mdata = {}
        metadata.each do |m|
          mdata[m[0]] = m[1]
        end


        
        send_data measurements.columns_with_metadata(@varnames, mdata),
           filename: file_root+'.json'
      }
      
    end
  end
    
  # GET /instruments/new
  def new
    authorize! :manage, Instrument

    @instrument = Instrument.new
  end

  # GET /instruments/1/edit
  def edit
  end

  # POST /instruments
  # POST /instruments.json
  def create
    authorize! :manage, Instrument

    @instrument = Instrument.new(instrument_params)

    respond_to do |format|
      if @instrument.save
        format.html { redirect_to @instrument, notice: 'Instrument was successfully created.' }
        format.json { render :show, status: :created, location: @instrument }
      else
        format.html { render :new }
        format.json { render json: @instrument.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /instruments/1
  # PATCH/PUT /instruments/1.json
  def update
    authorize! :manage, Instrument
        
    respond_to do |format|
      if @instrument.update(instrument_params)
        format.html { redirect_to @instrument, notice: 'Instrument was successfully updated.' }
        format.json { render :show, status: :ok, location: @instrument }
      else
        format.html { render :edit }
        format.json { render json: @instrument.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /instruments/1
  # DELETE /instruments/1.json
  def destroy
    authorize! :manage, Instrument
    
    Measurement.delete_all "instrument_id = #{@instrument.id}"
    @instrument.destroy
    respond_to do |format|
      format.html { redirect_to instruments_url, notice: 'Instrument was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instrument
      @instrument = Instrument.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def instrument_params
      params.require(:instrument).permit(
        :name, :site_id, :display_points, :sample_rate_seconds, :description, :instrument_id)
    end

end
