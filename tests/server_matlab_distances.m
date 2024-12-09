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

distances = [10, 50, 100, 300, 500, 1000, 4000];
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
                process_data(msg, distances, frequency, hB, hR, Cm);
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

function process_data(data_raw, distances, frequency, hB, hR, Cm)
    fs = 23040000;
    fprintf("size data: %d\n", length(data_raw));
    
    
    data_slice = data_raw;
    floatArray = typecast(uint8(data_slice), 'single');
    complexArray = complex(floatArray(1:2:end), floatArray(2:2:end));
    data_complex = complexArray(1:128*180);
    
    fprintf("size complex data: %d\n", length(data_complex));
    
    
    RSRP = zeros(size(distances));
    SINR = zeros(size(distances));
    RSRQ = zeros(size(distances));
    
    
    for i = 1:length(distances)
        d_m = distances(i); 
        d_km = d_m / 1000; 
        
        
        PL = calculatePathLoss(d_km, frequency, hB, hR, Cm);
        fprintf('Distance: %.2f m | Path Loss: %.2f dB\n', d_m, PL);
        
        
        scale_factor = 10^(-PL / 20);
        
        
        scaled_samples = data_complex * scale_factor;
        
        
        RSRP(i) = mean(abs(scaled_samples)); 
        
        
        noise_power = 1e-9; 
        interference_power = 0.5 * mean(abs(scaled_samples)); 
        SINR(i) = RSRP(i) / (noise_power + interference_power);
        
        
        RSRQ(i) = RSRP(i) / (noise_power + interference_power);
    end
    
    
    disp('Distance (m) | RSRP (dBm) | SINR (dB) | RSRQ (dB)');
    for i = 1:length(distances)
        fprintf('%13.2f | %.2f       | %.2f     | %.2f\n', distances(i), ...
            10*log10(RSRP(i)), 10*log10(SINR(i)), RSRQ(i));
    end
    
    
    subplot(3,1,1);
    plot(distances, 10*log10(RSRP), '-o');
    title('RSRP vs Distance');
    xlabel('Distance (m)');
    ylabel('RSRP (dBm)');
    grid on;

    subplot(3,1,2);
    plot(distances, 10*log10(SINR), '-o');
    title('SINR vs Distance');
    xlabel('Distance (m)');
    ylabel('SINR (dB)');
    grid on;

    subplot(3,1,3);
    plot(distances, RSRQ, '-o');
    title('RSRQ vs Distance');
    xlabel('Distance (m)');
    ylabel('RSRQ (dB)');
    grid on;

end
function PL = calculatePathLoss(d_km, f_MHz, hB_m, hR_m, C_m)
    
    a_hR_f = a(hR_m, f_MHz); 
    PL = 46.3 + 33.9 * log10(f_MHz) - ...
         13.82 * log10(hB_m) - a_hR_f + ...
         (44.9 - 6.55 * log10(hB_m)) * log10(d_km) + C_m;
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