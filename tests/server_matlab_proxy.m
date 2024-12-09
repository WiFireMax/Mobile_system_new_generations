clear java;
javaaddpath('home/firemax/Mobile_system_new_generations/src/jeromq-0.6.0')

import org.zeromq.ZMQ.*;
import org.zeromq.*;

port_api = 2111;
context = ZMQ.context(1);
socket_api_proxy = context.socket(ZMQ.REP);
socket_api_proxy.bind(sprintf('tcp://*:%d', port_api));

fprintf("Start")
figure(1);
global pauseFlag;
pauseFlag = false;
uicontrol('Style', 'pushbutton', 'String', 'Pause/Resume', ...
              'Position', [20, 20, 100, 30], ...
              'Callback', @(src, event) togglePause());
while true
    
    if ~pauseFlag
        msg = socket_api_proxy.recv();
        if ~isempty(msg)
            fprintf('received message [%d]\n', length(msg));
            if(length(msg) > 1000)
                process_data(msg);
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
function process_data(data_raw)
    fs = 23040000; % Sampling frequency
    fprintf("size data: %d\n", length(data_raw));
    data_slice = data_raw;
    floatArray = typecast(uint8(data_slice), 'single');
    complexArray = complex(floatArray(1:2:end), floatArray(2:2:end));
    data_complex = complexArray(1:128*180);
    
    % Define distance (d in km) and frequency (f in MHz)
    d = 1; % Example distance in kilometers
    f = 900; % Example frequency in megahertz

    % Calculate Path Loss
    PL = calculatePathLoss(d, f);
    fprintf("Calculated Path Loss: %.2f dB\n", PL);
    
    % Calculate scale factor based on Path Loss
    scale_factor = 10^(-PL / 20);
    
    % Apply Path Loss scaling to the complex data
    scaled_data_complex = data_complex * scale_factor;

    fprintf("size complex data: %d\n", length(scaled_data_complex));
    cla;
    
    window = 128;    
    noverlap = 0; 
    nfft = 128;      
    
    if any(isnan(scaled_data_complex))
        scaled_data_complex(isnan(scaled_data_complex)) = 0;
    end
    
    subplot(2, 1, 1);
    x_t = 1:length(scaled_data_complex);
    plot(x_t, scaled_data_complex);
    title('Данные в временной области (с учетом потерь)');
    xlabel('Отсчеты');
    ylabel('Амплитуда');
    
    subplot(2, 1, 2);
    spectrogram(scaled_data_complex, window, noverlap, nfft, fs, 'yaxis');
    title('Спектрограмма переданных данных (с учетом потерь)');
    xlabel('Время (сек)');
    ylabel('Частота (Гц)');
    colorbar;
    grid on;
    
    drawnow;
end

function PL = calculatePathLoss(d, f)
    % Calculate Path Loss using the formula
    PL = 28.0 + 22 * log10(d) + 20 * log10(f);
end