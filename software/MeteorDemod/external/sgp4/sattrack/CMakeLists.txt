set(SRCS
    sattrack.cc)

add_executable(sattrack
    ${SRCS})
target_link_libraries(sattrack
    sgp4)
