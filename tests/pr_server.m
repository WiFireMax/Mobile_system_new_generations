function proxy_server()
    % Укажите путь к JeroMQ JAR файлу
    JARPATH = 'jeromq/target/jeromq-0.4.4-SNAPSHOT.jar'; % Убедитесь, что путь правильный
    javaclasspath(JARPATH); % Добавление JAR файла в Java classpath

    % Импорт необходимых классов
    import org.zeromq.ZContext;
    import org.zeromq.ZMQ;

    % Создание контекста ZeroMQ
    context = ZContext(); 

    % Создание сокетов
    frontend = context.createSocket(ZMQ.PULL); % Сокет для получения данных от srsenb
    backend = context.createSocket(ZMQ.PUSH);  % Сокет для отправки данных к srsue

    % Привязка сокетов к портам
    frontend.bind('tcp://*:3000'); % Порт для srsenb
    backend.bind('tcp://*:3001');   % Порт для srsue

    disp('Proxy server is running...');
    
    % Инициализация массива для хранения сэмплов
    samples = [];

    try
        disp('Waiting for samples...');
        while true
            % Получение данных от srsenb
            sample = frontend.recv(0);  % 0 - блокирующий вызов
            
            if isempty(sample)
                disp('No sample received.');
            else
                disp('Received sample data.');
                % Преобразование байтового массива в числовой массив (например, double)
                sampleData = typecast(uint8(sample), 'double');
                
                % Отправка данных к srsue
                backend.send(sample);
                
                % Добавление полученных данных в массив для визуализации
                samples = [samples; sampleData]; %#ok<AGROW>

                % Визуализация данных
                plot(samples);
                xlabel('Sample Index');
                ylabel('Amplitude');
                title('Received Samples from srsenb');
                grid on;
                xlim([0 length(samples)]);
                
                pause(0.1); % Задержка для обновления графика
            end
        end
    catch ME
        disp('Error occurred:');
        disp(ME.message);
        disp(ME.stack); % Показать стек вызовов для диагностики
    end

    % Закрытие сокетов и контекста по завершении работы
    frontend.close();
    backend.close();
    context.close();
end
