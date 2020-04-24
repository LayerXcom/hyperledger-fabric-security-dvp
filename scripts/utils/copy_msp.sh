# usage: copy_msp src dist
function copy_msp () {
    mkdir -p $2

    for DIR_NAME in admincerts cacerts signcerts
    do
        cp -r $1/$DIR_NAME $2/
    done

    # cp $1/config.yaml $2/config.yaml
}

# usage: copy_msp src dist
function copy_msp_including_keystore () {
    mkdir -p $2

    for DIR_NAME in admincerts cacerts signcerts keystore
    do
        cp -r $1/$DIR_NAME $2/
    done

    # cp $1/config.yaml $2/config.yaml
}
