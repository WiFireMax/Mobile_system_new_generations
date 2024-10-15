#include </home/firemax/Mobile_system_new_generations/include/project.h>

// Функция обратного вызова для обработки пакетов
void packet_handler(u_char *user_data, const struct pcap_pkthdr *header, const u_char *packet) {
    // Получаем указатель на Ethernet заголовок
    struct ether_header *eth_header = (struct ether_header *)packet;

    // Если это IP-пакет
    if (ntohs(eth_header->ether_type) == ETHERTYPE_IP) {
        // Переходим к IP-заголовку
        const struct ip *ip_header = (struct ip *)(packet + sizeof(struct ether_header));
        int ip_header_len = ip_header->ip_hl * 4; // Длина IP заголовка

        // Выводим информацию о IP-адресах источника и назначения
        char src_ip[INET_ADDRSTRLEN];
        char dst_ip[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(ip_header->ip_src), src_ip, INET_ADDRSTRLEN);
        inet_ntop(AF_INET, &(ip_header->ip_dst), dst_ip, INET_ADDRSTRLEN);
        printf("Source IP: %s\n", src_ip);
        printf("Destination IP: %s\n", dst_ip);

        // Выводим размер заголовочной части IP-пакета
        printf("IP Header Length: %d bytes\n", ip_header_len);

        // Если это TCP-пакет
        if (ip_header->ip_p == IPPROTO_TCP) {
            // Переходим к TCP-заголовку
            const struct tcphdr *tcp_header = (struct tcphdr *)(packet + sizeof(struct ether_header) + ip_header_len);
            int tcp_header_len = tcp_header->th_off * 4; // Длина TCP заголовка

            // Переходим к полезной нагрузке
            const u_char *payload = packet + sizeof(struct ether_header) + ip_header_len + tcp_header_len;
            int payload_len = ntohs(ip_header->ip_len) - (ip_header_len + tcp_header_len);

            // Выводим побайтово значения поля Payload
            if (payload_len > 0) {
                printf("Payload (%d bytes):\n", payload_len);
                for (int i = 0; i < payload_len; i++) {
                    printf("%02x ", payload[i]);
                    if ((i + 1) % 16 == 0) {
                        printf("\n"); // Форматированный вывод по 16 байт в строке
                    }
                }
                printf("\n");
            } else {
                printf("No Payload\n");
            }
        }
    }
}

int main (void) {
    // Инициализируем ZeroMQ
    void *context = zmq_ctx_new();
    void *responder = zmq_socket(context, ZMQ_REP);
    int rc = zmq_bind(responder, "tcp://*:5555");
    assert(rc == 0);

    // Инициализируем pcap для захвата пакетов
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle = pcap_open_live("lo", BUFSIZ, 1, 1000, errbuf); // Используем интерфейс lo для тестирования
    if (handle == NULL) {
        fprintf(stderr, "Couldn't open device: %s\n", errbuf);
        return 2;
    }

    while (1) {
        // Получаем сообщения через ZeroMQ
        char buffer[10];
        zmq_recv(responder, buffer, 10, 0);
        //printf("Received Hello\n");
        printf("\n");
        // Захватываем один пакет и обрабатываем его
        struct pcap_pkthdr header;
        const u_char *packet = pcap_next(handle, &header);
        if (packet != NULL) {
            printf("Captured a packet of length %d\n", header.len);
            packet_handler(NULL, &header, packet); // Обрабатываем пакет
        }

        // Ответ на запрос ZeroMQ
        sleep(1); // Имитируем работу
        zmq_send(responder, "World", 5, 0);
    }

    // Закрываем pcap и ZeroMQ
    pcap_close(handle);
    zmq_close(responder);
    zmq_ctx_destroy(context);

    return 0;
}