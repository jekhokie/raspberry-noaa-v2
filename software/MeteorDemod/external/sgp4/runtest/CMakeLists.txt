set(SRCS
    runtest.cc)

add_executable(runtest
    ${SRCS})
target_link_libraries(runtest
    sgp4)
