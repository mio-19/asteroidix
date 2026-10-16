do_configure:prepend() {
    sed -i 's/find_package(AsteroidApp REQUIRED)/find_package(AsteroidApp6 REQUIRED)/g' ${S}/CMakeLists.txt
    sed -i 's/include(AsteroidCMakeSettings)/include(Asteroid6CMakeSettings)/g' ${S}/CMakeLists.txt
    sed -i 's/include(AsteroidTranslations)/include(Asteroid6Translations)/g' ${S}/CMakeLists.txt
    sed -i 's/Asteroid::AsteroidApp/Asteroid::AsteroidApp6/g' ${S}/src/CMakeLists.txt
}
