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

% Определение расстояний для расчета
distances = [10, 50, 100, 300, 500, 1000, 4000]; % Расстояния в метрах
frequency = 900; % Частота в МГц

while true
    if ~pauseFlag
        msg = socket_api_proxy.recv();
        if ~isempty(msg)
            fprintf('received message [%d]\n', length(msg));
            if(length(msg) > 1000)
                process_data(msg, distances, frequency);
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

function process_data(data_raw, distances, frequency)
    fs = 23040000;
    fprintf("size data: %d\n", length(data_raw));
    
    % Преобразование данных в комплексный формат
    data_slice = data_raw;
    floatArray = typecast(uint8(data_slice), 'single');
    complexArray = complex(floatArray(1:2:end), floatArray(2:2:end));
    data_complex = complexArray(1:128*180);
    
    fprintf("size complex data: %d\n", length(data_complex));
    
    % Инициализация массивов для хранения результатов
    RSRP = zeros(size(distances));
    SINR = zeros(size(distances));
    RSRQ = zeros(size(distances));
    
    % Цикл по каждому расстоянию для расчета метрик
    for i = 1:length(distances)
        d = distances(i);
        
        % Расчет затухания радиосигнала по модели Cost-Hata
        PL = calculatePathLoss(d, frequency);
        fprintf('Distance: %.2f m | Path Loss: %.2f dB\n', d, PL);
        
        % Преобразование затухания из дБ в линейный коэффициент
        scale_factor = 10^(-PL / 20);
        
        % Применение затухания к массиву сэмплов
        scaled_samples = data_complex * scale_factor;
        
        % Вычисление RSRP (Сигнал на уровне опорного сигнала)
        RSRP(i) = mean(abs(scaled_samples)); % Пример расчета
        
        % Вычисление SINR (Отношение сигнала к шуму и помехам)
        noise_power = 1e-9; % Пример мощности шума в ваттах
        interference_power = 0.5 * mean(abs(scaled_samples)); % Пример мощности помехи
        SINR(i) = RSRP(i) / (noise_power + interference_power); % Пример расчета
        
        % Вычисление RSRQ (Качество опорного сигнала)
        RSRQ(i) = RSRP(i) / (noise_power + interference_power); % Упрощенный пример
    end
    
    % Отображение результатов
    disp('Distance (m) | RSRP (dBm) | SINR (dB) | RSRQ (dB)');
    for i = 1:length(distances)
        fprintf('%13.2f | %.2f       | %.2f     | %.2f\n', distances(i), ...
            10*log10(RSRP(i)), 10*log10(SINR(i)), RSRQ(i));
    end
    
    % Построение графиков результатов
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

function PL = calculatePathLoss(d, f)
    % Расчет затухания радиосигнала по модели Cost-Hata
    if d < 1
        d = 1; % Минимальное расстояние для избежания log(0)
    end
    PL = 28 + 22 * log10(d) + 20 * log10(f);
end