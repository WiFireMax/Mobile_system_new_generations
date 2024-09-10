cmake_minimum_required(VERSION 3.15)
project(mob_sys)

# Исходные файлы проекта
set(SERVER_SOURCES
tests/server.c
)

set(CLIENT_SOURCES
tests/client.c
)

set(HEADERS
include/project.h
)

# Найти библиотеку libzmq
find_library(LIBZMQ_LIBRARY zmq)
find_path(LIBZMQ_INCLUDE_DIR zmq.h)

# Найти библиотеку czmq
find_library(CZMQ_LIBRARY czmq)
find_path(CZMQ_INCLUDE_DIR czmq.h)

# Путь до необходимых библиотек
include_directories(${PATH}/libzmq)
link_directories(${PATH}/libzmq)

include_directories(${PATH}/czmq)
link_directories(${PATH}/czmq)

# Добавление исполняемых файлов
add_executable(server ${SERVER_SOURCES})
add_executable(client ${CLIENT_SOURCES})

# Линковка с библиотеками libzmq и czmq
target_link_libraries(server ${LIBZMQ_LIBRARY} ${CZMQ_LIBRARY})
target_link_libraries(client ${LIBZMQ_LIBRARY} ${CZMQ_LIBRARY})
