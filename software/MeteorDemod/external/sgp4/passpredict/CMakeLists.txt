set(SRCS
    passpredict.cc)

add_executable(passpredict
    ${SRCS})
target_link_libraries(passpredict
    sgp4)
