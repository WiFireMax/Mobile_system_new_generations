function proxy_server()
    % Укажите путь к JeroMQ JAR файлу
    JARPATH = 'jeromq/target/jeromq-0.4.4-SNAPSHOT.jar';
    javaclasspath(JARPATH);
    
    % Импорт необходимых классов
    import org.zeromq.*;
    
    % Создание контекста и сокетов
    context = ZContext();
    socket_enb = context.createSocket(SocketType.REP); % Сокет для srsENB
    socket_ue = context.createSocket(SocketType.REP);  % Сокет для srsUE
    
    % Привязка сокетов к портам
    socket_enb.bind('tcp://*:3000'); % Порт для srsENB
    socket_ue.bind('tcp://*:3001');  % Порт для srsUE
    
    disp('Proxy server запущен.');

    while true
        % Чтение данных от srsENB
        msg_enb = socket_enb.recv(0);
        fprintf('Received from srsENB: [%s]\n', char(msg_enb(:)'));
        
        % Отправка данных к srsUE
        if ~isempty(msg_enb)
            send_samples(socket_ue, msg_enb);
        else
            fprintf('No message received from srsENB.\n');
        end
        
        % Чтение данных от srsUE
        msg_ue = socket_ue.recv(0);
        fprintf('Received from srsUE: [%s]\n', char(msg_ue(:)'));
        
        % Отправка данных обратно к srsENB (если необходимо)
        if ~isempty(msg_ue)
            socket_enb.send(msg_ue, 0);
        else
            fprintf('No message received from srsUE.\n');
        end
        
        % Визуализация данных на графике
        plot_data(msg_enb, msg_ue);
    end

    % Закрытие сокетов (не достигнет этой строки в бесконечном цикле)
    socket_enb.close();
    socket_ue.close();
end

function send_samples(socket, samples)
    % Преобразование данных в нужный формат для отправки
    zmq_msg = java.nio.ByteBuffer.allocate(length(samples));
    zmq_msg.put(samples);
    
    try
        % Отправка сообщения через сокет
        rc = socket.send(zmq_msg.array(), 0);
        
        if rc == -1
            error('Ошибка при отправке сэмплов');
        end
    catch ME
        fprintf('Error sending samples: %s\n', ME.message);
    end
end

function plot_data(data_enb, data_ue)
    % Преобразование данных в числовой формат для визуализации
    samples_enb = str2num(char(data_enb(:)')); %#ok<ST2NM>
    samples_ue = str2num(char(data_ue(:)')); %#ok<ST2NM>
    
    % Визуализация данных на графике
    figure(1);
    hold on;
    
    t_enb = 1:length(samples_enb);
    t_ue = 1:length(samples_ue);
    
    subplot(2, 1, 1);
    plot(t_enb, samples_enb);
    title('Сэмплы от srsENB');
    xlabel('Время');
    ylabel('Амплитуда');
    
    subplot(2, 1, 2);
    plot(t_ue, samples_ue);
    title('Сэмплы от srsUE');
    xlabel('Время');
    ylabel('Амплитуда');
    
    drawnow; % Обновление графика
end
