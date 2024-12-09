clear java;
javaaddpath('home/firemax/Mobile_system_new_generations/src/jeromq-0.6.0')

import org.zeromq.ZMQ.*;
import org.zeromq.*;

port_api = 2111;
context = ZMQ.context(1);
socket_api_proxy = context.socket(ZMQ.REP);
socket_api_proxy.bind(sprintf('tcp://*:%d', port_api));

fprintf("Start\n");
figure(1);
global pauseFlag;
pauseFlag = false;
uicontrol('Style', 'pushbutton', 'String', 'Pause/Resume', ...
          'Position', [20, 20, 100, 30], ...
          'Callback', @(src, event) togglePause());


srsenb_pos = [50, 50]; 
srsue_pos = [1200, 1150];


distance_km = sqrt((srsue_pos(1) - srsenb_pos(1))^2 + (srsue_pos(2) - srsenb_pos(2))^2) / 1000; % Расстояние в километрах
fprintf('Расстояние между srsenb и srsue: %.2f километров\n', distance_km);


frequency = 900; 
hB = 30; 
hR = 1.5; 
Cm = 0; 

while true
    if ~pauseFlag
        msg = socket_api_proxy.recv();
        if ~isempty(msg)
            fprintf('received message [%d]\n', length(msg));
            if(length(msg) > 1000)
                process_data(msg, distance_km, frequency, hB, hR, Cm);
            end
            socket_api_proxy.send("OK");
        end
    else
        pause(0.1);
    end
end

function togglePause()
    global pauseFlag;
    pauseFlag = ~pauseFlag;
end

function process_data(data_raw, distance_km, frequency, hB, hR, Cm)
    fs = 23040000;
    fprintf("size data: %d\n", length(data_raw));
    
    
    data_slice = data_raw;
    floatArray = typecast(uint8(data_slice), 'single');
    complexArray = complex(floatArray(1:2:end), floatArray(2:2:end));
    data_complex = complexArray(1:128*180);
    
    fprintf("size complex data: %d\n", length(data_complex));
    
    
    PL = calculatePathLoss(distance_km, frequency, hB, hR, Cm);
    fprintf('Distance: %.2f km | Path Loss: %.2f dB\n', distance_km, PL);
    
   
    scale_factor = 10^(-PL / 20);
    
    
    scaled_samples = data_complex * scale_factor;
    
    
    RSRP = mean(abs(scaled_samples));
    
    
    noise_power = 1e-9; 
    interference_power = 0.5 * mean(abs(scaled_samples));
    SINR = RSRP / (noise_power + interference_power);
    
    
    RSRQ = RSRP / (noise_power + interference_power); 
    
    
    fprintf('RSRP: %.2f dBm | SINR: %.2f dB | RSRQ: %.2f dB\n', ...
        10*log10(RSRP), 10*log10(SINR), RSRQ);
end

function PL = calculatePathLoss(d_km, f_MHz, hB_m, hR_m, C_m)
    
    a_hR_f = a(hR_m, f_MHz); 
    Lb = 46.3 + 33.9 * log10(f_MHz) - 13.82 * log10(hB_m) - a_hR_f + ...
         (44.9 - 6.55 * log10(hB_m)) * log10(d_km) + C_m;
    
    PL = Lb; 
end

function a_hR_f = a(hR_m, f_MHz)
    
    if f_MHz >= 150 && f_MHz <= 200
        a_hR_f = 8.29 * (log10(1.54 * hR_m))^2 - 1.1;
    elseif f_MHz > 200 && f_MHz <= 1500
        a_hR_f = 3.2 * (log10(11.75 * hR_m))^2 - 4.97;
    else
        a_hR_f = 0; 
    end
end