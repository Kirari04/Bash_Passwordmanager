#!/bin/bash
name="Password Manager";
dataFolder="data";
globalPasswordVerifyString="randomstring";
globalPasswordVerifyFile="passwordmanager.gpg";
globalPassword="";
w=100;
h=100;
running=true;

## check if is setup
if [[ -e $globalPasswordVerifyFile ]]; then
    echo "skipping";
else
    globalPassword=$(dialog --passwordbox "Set your password" $w $h --output-fd 1);
    echo $globalPasswordVerifyString \
      | gpg --symmetric --armor --batch --passphrase "$globalPassword" -o "$globalPasswordVerifyFile";
fi;

## verify password
globalPasswordMatch=false;
while [ $globalPasswordMatch = false ]; do
    globalPassword=$(dialog --passwordbox "Enter your password" $w $h --output-fd 1);
    clearTextFileData=$(gpg --batch --passphrase "$globalPassword" -d "$globalPasswordVerifyFile");
    if [[ $clearTextFileData == $globalPasswordVerifyString ]]; then
        globalPasswordMatch=true;
        dialog --msgbox "Password is correct\nWellcome to $name" $w $h;
    else
        dialog --msgbox "Password is incorrect" $w $h;
    fi;
done;

## run main programm
while [ $running = true ]; do
    ## Menu
    selected=$(dialog --menu "$name" $w $h $h \
    1 "Beenden" \
    2 "List" \
    3 "Create" \
    --output-fd 1);

    ## Stop script
    if [[ $selected -eq 1 || $selected == "" ]]; then
        running=false;
        clear;
        echo "$name wurde beendet.";
    fi;

    ## List / Show data
    if [[ $selected -eq 2 ]]; then
        menuList="";
        nth=1;
        for n in $(ls -1 "$dataFolder"); do
            identifier=$(echo $n | cut -d '.' -f 1);
            menuList+="'$nth' '$identifier' ";
            nth=$((nth+1));
        done;

        res=$(eval $(echo "dialog --menu \"$name - List\" $w $h $h $menuList --output-fd 1"));

        ## show selected dataset
        if [[ $res != "" ]]; then
            showDataSet=true;

            while [ $showDataSet = true ]; do
                selected=$(dialog --menu "$name - Choose what to do with the dataset" $w $h $h \
                1 "Show Data" \
                2 "Delete Data" \
                --output-fd 1);

                # exit dataset
                if [[ $selected == "" ]]; then
                    showDataSet=false;
                fi;

                # show dataset
                if [[ $selected -eq 1 ]]; then
                    currentFile=$(ls -1 $dataFolder | sed -n $(echo $res)p);
                    encTextFile="$dataFolder/$currentFile";
                    clearTextFileData=$(gpg --batch --passphrase "$globalPassword" -d "$encTextFile");
                    password=$(echo $clearTextFileData | cut -d ';' -f 3 | base64 --decode);
                    email=$(echo $clearTextFileData | cut -d ';' -f 2 | base64 --decode);
                    dialog --msgbox "Your Email: $email\nYour password is: $password" $w $h;
                fi;

                # delete dataset
                if [[ $selected -eq 2 ]]; then
                    showDataSet=false;
                    currentFile=$(ls -1 $dataFolder | sed -n $(echo $res)p);
                    rm "$dataFolder/$currentFile";
                    dialog --msgbox "$currentFile has been deleted" $w $h;
                fi;
            done;
        fi;
    fi;

    ## Create new entry
    if [[ $selected -eq 3 ]]; then
        skipProcess=false;
        isUnique=false;
        while [ $isUnique == false ]; do
            identifier=$(dialog --inputbox "Identifier (it has to be unique)" $w $h --output-fd 1);
            if [[ $identifier == "" ]]; then
                skipProcess=true;
                isUnique=true;
            fi;
            if [[ $skipProcess == false ]]; then
                encTextFile="$dataFolder/$identifier.gpg";
                if [[ -e $encTextFile ]]; then
                    dialog --msgbox "The identifier $identifier is not unique!\nPlease try again" $w $h;
                else
                    if [[ $identifier == *";"* ]]; then
                        dialog --msgbox "The identifier can't contain the ';' character." $w $h;
                    else
                        isUnique=true;
                    fi;
                fi;
            fi;
        done

        if [[ $skipProcess == false ]]; then
            username=$(dialog --inputbox "Username or Email" $w $h --output-fd 1);
            username=$(echo $username | base64);
        fi;
        if [[ $skipProcess == false ]]; then
            password=$(dialog \
                --passwordbox "Password (the input is not shown for security reasons)" $w $h --output-fd 1);
            password=$(echo $password | base64);
        fi;

        if [[ $skipProcess == false ]]; then
            echo "$identifier;$username;$password" | gpg --symmetric --armor --batch --passphrase "$globalPassword" -o "$encTextFile";
        fi;
    fi;
done;
