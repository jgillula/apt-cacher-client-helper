REVISION=1

options=`getopt -o r: --long revision -n "${0##*/}" -- "$@"`

eval set -- "$options"

while true ; do
    case "$1" in
        -r|--revision)
            case "$2" in
                "") shift 2 ;;
                *) REVISION=$2 ; shift 2 ;;
            esac
            ;;
        --) shift ; break ;;
        *) >&2 echo "Error: Problem parsing command-line arguments!" ; exit 1 ;;
    esac    
done

# Get the current version
BUILD_VERSION=$(cat ../VERSION)

# Make the build directory
BUILD_DIR="apt-cacher-client-helper_${BUILD_VERSION}-${REVISION}_all"
mkdir -p "${BUILD_DIR}"

# Load the file paths to put the files
. file_paths.sh

# Move all the files
for path in "${!file_paths[@]}"; do
    mkdir -p "${BUILD_DIR}/${path}"
    declare -a files=(${file_paths["$path"]})
    for file in "${files[@]}"; do
        cp "../src/${file}" "${BUILD_DIR}/${path}/${file}"

        if [ "${file}" == "common_functions.sh" ]; then
            # Fix the version number
            . "${BUILD_DIR}/${path}/${file}"
            sed -i -e "s/VERSION=.*/VERSION=\"$(regex_escape $BUILD_VERSION)\"/" "${BUILD_DIR}/${path}/${file}"
        fi

        sed -i -e "s|APT_CACHER_CLIENT_HELPER_LIB_DIR=\".*\"|APT_CACHER_CLIENT_HELPER_LIB_DIR=\"/usr/lib/apt-cacher-client-helper\"|" "${BUILD_DIR}/${path}/${file}"
    done
done

rm -rf "${BUILD_DIR}/DEBIAN"
cp -r DEBIAN "${BUILD_DIR}/DEBIAN"
sed -i -e "s/VERSION/$(regex_escape $BUILD_VERSION)/" "${BUILD_DIR}/DEBIAN/control"

dpkg-deb --build "${BUILD_DIR}"
