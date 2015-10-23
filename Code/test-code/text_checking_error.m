% Check non-persistent CSMA
check_station = 1;
previous_state = record_state(check_station, 1);
error = 0;
error_list = [];
for i = 2:TOTAL_SLOT_NUMBER
    current_state = record_state(check_station, i);
    switch ( previous_state )
        case 0
            if current_state == 1 || current_state == 2
                error=error+1;
                error_list = [error_list i];
            end
        case 1
            if current_state == 2
                error=error+1;
                error_list = [error_list i];
            end
        case 2
            if current_state == 0 || current_state == 1
                error=error+1;
                error_list = [error_list i];
            end
        case 3
            if current_state == 0
                error=error+1;
                error_list = [error_list i];
            end
    end
    previous_state= current_state;
end

error