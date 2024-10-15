cmake_minimum_required(VERSION 3.10)

# Установите имя проекта
project(Client_Server)

set(CMAKE_C_STANDARD 99)

# Найти библиотеки pcap
find_package(PkgConfig REQUIRED)
pkg_check_modules(PCAP REQUIRED libpcap)

pkg_check_modules(ZMQ REQUIRED libzmq)
pkg_check_modules(CZMQ REQUIRED libczmq)

# Создайте исполняемые файлы для сервера и клиента
add_executable(server tests/server.c)  
add_executable(client tests/client.c)  

#add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/test)

# Свяжите библиотеки с исполняемыми файлами
target_link_libraries(server ${ZMQ_LIBRARIES} ${CZMQ_LIBRARIES} ${PCAP_LIBRARIES})
target_link_libraries(client ${ZMQ_LIBRARIES} ${CZMQ_LIBRARIES} ${PCAP_LIBRARIES})

# Включите директории заголовков
target_include_directories(server PUBLIC  
    ${ZMQ_INCLUDE_DIRS}
    ${CZMQ_INCLUDE_DIRS}
    ${PCAP_INCLUDE_DIRS}
)

target_include_directories(client PUBLIC  
    ${ZMQ_INCLUDE_DIRS}
    ${CZMQ_INCLUDE_DIRS}
    ${PCAP_INCLUDE_DIRS}
)
