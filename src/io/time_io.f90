module time_io

    use data_structures
    use string
    use time
    use io_routines, only : io_read, io_read_attribute
    
    implicit none
    
contains
    
    function time_gain_from_units(units) result(gain)
        implicit none
        character(len=MAXSTRINGLENGTH), intent(in) :: units
        real :: gain
        
        if ((units(1:4)=="days").or.(units(1:4)=="Days")) then
            gain = 1.0
        else if ((units(1:4)=="hour").or.(units(1:4)=="Hour")) then
            gain = 1/24.0
        else
            write(*,*) units
            stop "Error: unknown units"
        endif
        
    end function time_gain_from_units
    
    subroutine read_times(options, times)
        implicit none
        type(input_config), intent(in) :: options
        type(Time_type), intent(inout), dimension(:) :: times
        
        double precision, allocatable, dimension(:) :: temp_times
        integer :: ntimes, file_idx, cur_time, time_idx, error, start_year
        character(len=MAXSTRINGLENGTH) :: calendar, units
        real :: calendar_gain
        
        ntimes = size(times,1)
        cur_time = 1
        
        do file_idx = 1, size(options%file_names,1)
            
            ! first read the time variable (presumebly a 1D double precision array)
            call io_read(options%file_names(file_idx, options%time_file), options%time_name, temp_times)
            ! attempt to read the calendar attribute from the time variable
            call io_read_attribute(options%file_names(file_idx, options%time_file),"calendar", &
                                   calendar, var_name=options%time_name, error=error)
            ! if time attribute it not present, set calendar to one specified in the config file
            if (error/=0) then
                calendar = options%calendar
            endif

            ! attempt to read the units for this time variable
            call io_read_attribute(options%file_names(file_idx, options%time_file), "units", &
                                   units, var_name=options%time_name, error=error)
            ! in case it is in units of e.g. hours since
            calendar_gain = time_gain_from_units(units)
            temp_times = temp_times * calendar_gain
            
            print*, trim(units(12:15))
            if (error==0) then
                start_year = get_integer(units(12:15))
            else
                start_year = options%calendar_start_year
            endif
            
            do time_idx = 1, size(temp_times,1)
                
                call times(cur_time)%init(calendar, start_year)
                call times(cur_time)%set(temp_times(time_idx))
                print*, trim(times(cur_time)%as_string())
                
                cur_time = cur_time + 1
            end do
            
            deallocate(temp_times)
        end do
        
    end subroutine read_times

end module time_io
