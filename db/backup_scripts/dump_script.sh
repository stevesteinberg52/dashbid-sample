tables=( activity_logs ad_source_comments ad_source_groups ad_source_nestings ad_source_reconciliations ad_sources ad_sources_waterfall_comments build_tests convert_tz countries csv_parsers customer_comments customer_statement_dates customer_statements customers daily_revenues data_sources dbam_builds dbams definitions deploys domains groups hourly_margin_dates hourly_margins list_assignment_groups list_assignment_groups_list_assignments list_assignments list_builds list_domains list_events list_uploads lists margin_by_dates network_comments network_data network_reconciliations networks notification_recipients notifications pixalate_ips placement_comments placement_groups placements queries query_logs report_types repositories saved_reports schema_migrations td_as_dailies td_as_events td_domain_dailies td_domain_http_referers td_domain_referrers td_ip_impressions td_list_empty_vast td_server_performance_hourlies td_wf_dailies td_wf_events test_events test_pages uploads users versions waterfall_comments wopr_results )

function conditions {
    case $1 in
        "activity_logs" )
            CONDITIONS="--where=\"created_at >= '$ON_OR_AFTER'\"";;
        "ad_source_reconciliations" )
            CONDITIONS="--where=\"for_date >= '$ON_OR_AFTER'\"";;
        "hourly_margins" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "margin_by_dates" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
        "pixalate_ips" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
        "td_as_dailies" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "td_as_events" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "td_domain_dailies" )
            CONDITIONS="--where=\"dd = '$ON_OR_AFTER'\"";;
        "td_domain_http_referers" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
        "td_domain_referrers" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
        "td_ip_impressions" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
        "td_server_performance_hourlies" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "td_wf_dailies" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "td_wf_events" )
            CONDITIONS="--where=\"dd >= '$ON_OR_AFTER'\"";;
        "versions" )
            # Just create an empty table!
            CONDITIONS="--where=\"1=0\"";;
    esac
}

function process_tables {
    for i in "${!tables[@]}"
    do
        TABLE_NAME="${tables[$i]}"
        TABLE_INDEX=$(($i + 1))

        case $1 in
            "create" )
                echo "Dumping table $TABLE_NAME ($TABLE_INDEX of ${#tables[@]})"
                create_dump_file_for $TABLE_NAME;;
            "restore" )
                echo "Restoring table $TABLE_NAME ($TABLE_INDEX of ${#tables[@]})"
                restore_from_dump_file_for $TABLE_NAME;;
        esac
    done
}

function process_tables_from {
    ask_database_name_to_restore
    echo "Looking for uncompressed file: "$LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_"$tables".sql"
    if [ -f $LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_"$tables".sql" ]
    then
        echo "Skipping uncompress. Files are already uncompressed."
    else
        uncompress_dump_files
    fi

    for i in "${!tables[@]}"
    do
        if [[ "${tables[$i]}" = "${STARTING_TABLE}" ]]; then
            START_INDEX=$i
        fi
    done

    for i in "${!tables[@]}"
    do
        TABLE_NAME="${tables[$i]}"
        TABLE_INDEX=$(($i + 1))

        if [[ $i -ge $START_INDEX ]]; then
            echo "Restoring table $TABLE_NAME ($TABLE_INDEX of ${#tables[@]})"
            restore_from_dump_file_for $TABLE_NAME
        fi
    done
}

function create_dump_file_for {
    HOST="v-dbam-app-prod-read-01.cthu1k5vrvbb.us-east-1.rds.amazonaws.com"
    PASSWORD=dbam-app
    conditions $TABLE_NAME
    SERVER_PARAMS="--single-transaction -h $HOST -P3306 -u admin -p$PASSWORD dbamapp $TABLE_NAME $CONDITIONS"
    CREATED_DUMP_FILENAME=$DUMP_DATE"_"$TABLE_NAME.sql
    CREATED_DUMP_FILE_PATH="$SERVER_FOLDER/$CREATED_DUMP_FILENAME"

    run_remote_command "mysqldump $SERVER_PARAMS > $CREATED_DUMP_FILE_PATH"
    CONDITIONS=""
}

function compress_dump_files {
    printf "\nCompressing dump files ..."
    run_remote_command "cd $SERVER_FOLDER/ && tar -zcvf $DUMP_DATE\"_dumps.tar.gz\" $DUMP_DATE\"_\"*"
    echo "Done. You can download this file at: $SERVER_FOLDER/"$DUMP_DATE"_dumps.tar.gz"
}

function destroy_dump_files {
    printf "\nDeleting dump files ..."
    run_remote_command "cd $SERVER_FOLDER/ && rm $DUMP_DATE\"_\"*.sql"
    echo "Done."
}

function restore_from_dump_file_for {
    HOST=localhost
    SERVER_PARAMS="-h $HOST -u root $DATABASE_NAME"
    TO_RESTORE_FILENAME=$DUMP_DATE_TO_RESTORE"_"$TABLE_NAME.sql
    TO_RESTORE_FILE_PATH="$LOCAL_FOLDER/$TO_RESTORE_FILENAME"

    if [ -f "$TO_RESTORE_FILE_PATH" ]
    then
        mysql $SERVER_PARAMS < $TO_RESTORE_FILE_PATH
    else
        printf "File $TO_RESTORE_FILE_PATH not found. Check the path.\n"
        break
    fi
}

function download_dump {
    echo "Downloading dump file..."
    scp $SSH_INFO:$SERVER_FOLDER/$DUMP_DATE_TO_RESTORE"_dumps.tar.gz" $LOCAL_FOLDER
}

function ask_date_to_restore {
    printf "\nType the date of the dump that you want to restore in this format: YYYY-MM-DD.\n[ENTER] to use: $DUMP_DATE\n"
    read DUMP_DATE_TO_RESTORE
    DUMP_DATE_TO_RESTORE=${DUMP_DATE_TO_RESTORE:-"$DUMP_DATE"}
}

function ask_folder_to_restore {
    printf "\nWhat folder has your dump files? Type the exact path based on this current path ($(pwd)).\n[ENTER] to use: '../../tmp'\n"
    read LOCAL_FOLDER
    LOCAL_FOLDER=${LOCAL_FOLDER:-"../../tmp"}
}

function ask_database_name_to_restore {
    printf "\nWhat's the name of the database that will be overwrited by the dump files?\n[ENTER] to use: 'dbam-app_dev'\n"
    read DATABASE_NAME
    DATABASE_NAME=${DATABASE_NAME:-"dbam-app_dev"}
}

function ask_table_name_to_start {
    printf "\nWhat is the starting table to be processed in the order?\n"
    read STARTING_TABLE
}

function uncompress_dump_files {
    echo "Uncompressing dump pack: $DUMP_DATE_TO_RESTORE""_dumps.tar.gz"
    if [ -f $LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_dumps.tar.gz" ]
    then
        tar -xzvf $LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_dumps.tar.gz" -C $LOCAL_FOLDER/
    else
        printf "File $LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE""_dumps.tar.gz not found. Check the path.\n"
    fi
}

function ask_date_to_dump {
    BASH_OS=`uname`

    case $BASH_OS in
        "Linux" )
            LAST_DAY=`date --date='-1 day' +%Y-%m-%d`
            LAST_WEEK=`date --date='-7 days' +%Y-%m-%d`
            LAST_MONTH=`date --date='-1 month' +%Y-%m-%d`;;
        "Darwin" )
            LAST_DAY=`date -v -1d +%Y-%m-%d`
            LAST_WEEK=`date -v -7d +%Y-%m-%d`
            LAST_MONTH=`date -v -1m +%Y-%m-%d`;;
    esac

    printf "\nWhat date would you like to create this dump?\n[ENTER] to create a dump of a week ago ($LAST_WEEK)?."
    read ON_OR_AFTER
    ON_OR_AFTER=${ON_OR_AFTER:-$LAST_WEEK}
}

function run_remote_command {
    ssh $SSH_INFO $1
}

function create_action_steps {
    ask_date_to_dump
    process_tables "create"
    compress_dump_files
    destroy_dump_files
}

function restore_action_steps {
    ask_database_name_to_restore
    echo "Looking for uncompressed file: "$LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_"$tables".sql"
    if [ -f $LOCAL_FOLDER/$DUMP_DATE_TO_RESTORE"_"$tables".sql" ]
    then
        echo "Skipping uncompress. Files are already uncompressed."
    else
        uncompress_dump_files
    fi
    process_tables "restore"
}

function list_available_dumps {
    echo "Listing already generated dump files..."
    run_remote_command "ls "$SERVER_FOLDER/
}

time {
    printf "\nStarting script...\n"

    DUMP_DATE=`date +%Y-%m-%d`
    SERVER_FOLDER="/home/deployer/db_dumps"
    SSH_INFO=deployer@ec2-52-91-137-167.compute-1.amazonaws.com

    printf "\nWhat action would you like to do?\n"
    echo "   Type 'all' to run all steps (create, download and restore) in a single command;"
    echo "   Type 'create' to create a fresh new dump;"
    echo "   Type 'download' to download an already created dump;"
    echo "   Type 'restore' to restore an already created dump."
    echo "   Type 'restore_from' to restore an already created dump starting from a given table name."
    echo "   Type 'list' to list all already created dumps."
    read ACTION

    case $ACTION in
        "all" )
            create_action_steps
            DUMP_DATE_TO_RESTORE=$DUMP_DATE # Sets date to restore based on current dump date.
            ask_folder_to_restore
            download_dump
            restore_action_steps;;
        "create" )
            create_action_steps;;
        "download" )
            ask_date_to_restore
            ask_folder_to_restore
            download_dump;;
        "restore" )
            ask_date_to_restore
            ask_folder_to_restore
            restore_action_steps;;
        "restore_from" )
            ask_date_to_restore
            ask_folder_to_restore
            ask_table_name_to_start
            process_tables_from;;
        "list" )
            list_available_dumps;;
        * )
            printf "No action given. Please pass the 'create' or 'restore' as arguments of this script.";;
    esac

    printf "\n\nFinished running script.\n"
}
