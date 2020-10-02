<?php

@session_start(  );
header( 'Content-Type: text/html; charset=UTF-8' );

//if ($_SERVER['HTTP_HOST'] != '127.0.0.1') {
//    error_reporting(30719 & ~8192 & ~8 & ~2);
//    @set_magic_quotes_runtime(false);
//    ini_set('short_tags', false);
//}

ini_set( 'memory_limit', '2048M' );
ini_set( 'track_errors', true );
ini_set( 'magic_quotes_sybase', false );

include( 'database.php' );
include( dirname( dirname( __FILE__ ) ) . '/language/en.php' );
include_once( 'functions.php' );

$q = 'SELECT password  FROM user_account WHERE user_account_id =  \'' . $_SESSION['user_account_id'] . '\' ';
if (!( $r = mysql_query( $q ))) {
    exit(mysql_error());
}

$row = mysql_fetch_array( $r );
if ($row['password'] != $_SESSION['password']) {
    $_SESSION['user_account_id'] = 0;
    session_destroy();
    header('Location: login.php');
    exit();
}

//if (!isset( $_SESSION['white_label']['background_path'] )) {
    $q = 'SELECT * FROM white_label ';
    $r = mysql_query($q);
    $row = mysql_fetch_assoc($r);

    $_SESSION['white_label']['logo_path'] = $row['logo_path'];
    $_SESSION['white_label']['title'] = $row['title'];
    $_SESSION['white_label']['hide_footer'] = $row['hide_footer'];
    $_SESSION['white_label']['favicon_path'] = $row['favicon_path'];
    $_SESSION['white_label']['email_required'] = $row['email_required'];
    $_SESSION['white_label']['tag_line'] = $row['tag_line'];
    $_SESSION['white_label']['footer_licensed'] = $row['footer_licensed'];
    $_SESSION['white_label']['footer_powered'] = $row['footer_powered'];
    $_SESSION['white_label']['meta_title'] = $row['meta_title'];
    $_SESSION['white_label']['meta_keywords'] = $row['meta_keywords'];
    $_SESSION['white_label']['meta_description'] = $row['meta_description'];
    $_SESSION['white_label']['tracking_script'] = $row['tracking_script'];
    $_SESSION['white_label']['header_message'] = $row['header_message'];

    if ($row['background_path']) {
        $_SESSION['white_label']['background_path'] = ($row['background_path'] ? 'temp/' . $row['background_path'] : 'img/placeholders/headers/login_header.jpg');
    }

    if ($row['subscriber_label']) {
        $_SESSION['white_label']['subscriber_label'] = (true ? $row['subscriber_label'] : 'Subscriber');
    }
//}


$lic_res['companyname'] = 'XtreemPMTA.co';
$lis_res['regdate'] = '2016-11-25';
$lic_res['nextduedate'] = 'Never';

$active_addons_list = array();

// modules
array_push( $active_addons_list, 'Domain Masking');
array_push( $active_addons_list, 'Multi MTA / SMTP');
array_push( $active_addons_list, 'PowerMTA Integration and Bounce Processor');
array_push( $active_addons_list, 'Spin Tags');
array_push( $active_addons_list, 'Auto Backup Module');
array_push( $active_addons_list, 'White Labeling' );
array_push( $active_addons_list, 'Email Verifier' );
array_push( $active_addons_list, 'User Management' );
array_push( $active_addons_list, 'Geo Location Tool' );
array_push( $active_addons_list, 'Feedback Loops Processor' );
array_push( $active_addons_list, 'Dynamic Content Tags' );
array_push( $active_addons_list, 'Auto Responders' );
array_push( $active_addons_list, 'Adknowledge Integration' );
array_push( $active_addons_list, 'Responsive Newsletter Templates' );
array_push( $active_addons_list, 'IP/Domain Reputation Monitor' );
array_push( $active_addons_list, 'Split Tests' );
array_push( $active_addons_list, 'Triggers' );
array_push( $active_addons_list, 'Website Forms' );
array_push( $active_addons_list, 'Advance Export' );
array_push( $active_addons_list, 'White' );
array_push( $active_addons_list, 'Multi Campaign Scheduling' );
array_push( $active_addons_list, 'Multi Threading' );
array_push( $active_addons_list, 'Mandrill Integration' );
array_push( $active_addons_list, 'Sender Score Monitor' );
array_push( $active_addons_list, 'Domain Masking' );
array_push( $active_addons_list, 'Authentication Check' );
array_push( $active_addons_list, 'Server Maintenance Robot' );
$_SESSION['active_addons_list'] = $active_addons_list;


$template = array( 'name' => 'MUMARA', 'version' => '1.0', 'author' => '', 'robots' => 'noindex, nofollow', 'title' => 'MUMARA', 'description' => 'MUMARA', 'header_navbar' => 'navbar-default', 'header' => '', 'sidebar' => 'sidebar-partial sidebar-visible-lg sidebar-no-animations', 'footer' => '', 'main_style' => '', 'theme' => '', 'header_content' => '', 'active_page' => basename( $_SERVER['PHP_SELF'] ) );

$PRODUCTNAME = 'MUMARA';

$app_type = 2;
if( $PRODUCTNAME == "MUMARAESP" && isset($_SESSION["account_id"]) ) 
{
    $q = "SELECT app_type FROM user_account WHERE user_account_id = '" . $_SESSION["account_id"] . "' ";
    $r = mysql_query($q);
    $row = mysql_fetch_array($r);
    $app_type = $row["app_type"];
}

if( $app_type == 3 ) 
{
    $primary_nav = array( array( "name" => getMenuLabel("Dashboard"), "url" => "index.php", "icon" => "gi gi-stopwatch" ), array( "name" => getMenuLabel("My Lists"), "icon" => "gi gi-notes_2", "sub" => array( array( "name" => getMenuLabel("Create a List"), "url" => "new_list.php" ), array( "name" => getMenuLabel("View all Lists"), "url" => "view_lists.php" ) ) ), array( "name" => getMenuLabel("Subscribers"), "icon" => "gi gi-envelope", "sub" => array( array( "name" => getMenuLabel("Add a Subscriber"), "url" => "new_contacts.php" ), array( "name" => getMenuLabel("List all Subscribers"), "url" => "view_contacts.php" ) ) ), array( "name" => getMenuLabel("My Campaigns"), "icon" => "fa fa-exchange", "sub" => array( array( "name" => getMenuLabel("Create an Email Campaign"), "url" => "new_campaign.php" ), array( "name" => getMenuLabel("View all Email Campaigns"), "url" => "view_campaign.php" ), array( "name" => getMenuLabel("Schedule Email Campaign"), "url" => "schedule_campaign.php" ), array( "name" => getMenuLabel("View Scheduled Campaigns"), "url" => "view_schedule_campaign.php" ), array( "name" => getMenuLabel("Email Campaign Stats"), "url" => "view_stats_schedule_campaign.php" ), array( "name" => getMenuLabel("Image/File Manager"), "url" => "image_upload.php" ) ) ), array( "name" => getMenuLabel("Auto-Responders"), "icon" => "fa fa-bullhorn", "sub" => array( array( "name" => getMenuLabel("Create an Auto-Responder"), "url" => "new_autoresponders.php" ), array( "name" => getMenuLabel("View Auto-Responder"), "url" => "view_autoresponders.php" ) ) ), array( "name" => getMenuLabel("Trigger"), "icon" => "hi hi-time", "sub" => array( array( "name" => getMenuLabel("Create a Trigger"), "url" => "new_trigger.php" ), array( "name" => getMenuLabel("View Triggers"), "url" => "view_trigger.php" ), array( "name" => getMenuLabel("Trigger Notification Email"), "url" => "new_notification.php" ) ) ), array( "name" => getMenuLabel("Statistics"), "icon" => "gi gi-charts", "sub" => array( array( "name" => getMenuLabel("Email Campaign Stats"), "url" => "view_stats_schedule_campaign.php" ), array( "name" => getMenuLabel("Auto Responder Stats"), "url" => "view_stats_autoresponder.php" ), array( "name" => getMenuLabel("Auto Responder Group Stats"), "url" => "view_stats_autoresponder_group.php" ), array( "name" => getMenuLabel("Trigger Stats"), "url" => "view_stats_triggers.php" ) ) ) );
}
else
{
    if( !in_array("auto_backup", $hide_modules) ) 
    {
        $auto_backup = array( "name" => getMenuLabel("Auto Backup"), "url" => "database_backup.php" );
    }
    else
    {
        $auto_backup = array(  );
    }

    if( !in_array("api_integration", $hide_modules) ) 
    {
        $mumara_api = array( "name" => getMenuLabel("Email Application API"), "url" => "api_integration.php" );
    }
    else
    {
        $mumara_api = array(  );
    }

    $mandrill_menu = array( "name" => getMenuLabel("Mandrill Integration"), "url" => "mandrill_setting.php" );
    $dropbox_integration_menu = array(  );
    if( $PRODUCTNAME == "MUMARAESP" ) 
    {
        $pmta_integration_menu = array(  );
    }
    else
    {
        $pmta_integration_menu = array( "name" => getMenuLabel("PowerMTA Settings"), "url" => "pmta_setting.php" );
    }

    if( !in_array("white_labeling", $hide_modules) ) 
    {
        $whitelabel_menu = array( "name" => "White Labeling", "url" => "white_labeling.php" );
    }
    else
    {
        $whitelabel_menu = array(  );
    }

    if( checkModule("Multi Threading") ) 
    {
        $multithread_menu = array( "name" => "Multi Threading", "url" => "multi_threading.php" );
    }
    else
    {
        $multithread_menu = array(  );
    }

    $spintag_menu = array( "name" => getMenuLabel("Spintags"), "icon" => "fa fa-bullseye", "sub" => array( array( "name" => getMenuLabel("Create a Spintag"), "url" => "new_spin_tag.php" ), array( "name" => getMenuLabel("View all Spintags"), "url" => "view_spin_tag.php" ) ) );
    $fbl_menu = array( "name" => getMenuLabel("Feedback Loops(FBL)"), "icon" => "fa fa-check-circle-o", "sub" => array( array( "name" => getMenuLabel("Configure a Feedback Loop"), "url" => "new_feedback_loop.php" ), array( "name" => getMenuLabel("View Feedback Loops"), "url" => "view_feedback_loop.php" ), array( "name" => getMenuLabel("Processed Feedback Loops"), "url" => "view_feedback_loop_list.php" ) ) );
    $trigger_menu = array( "name" => getMenuLabel("Triggers (Actions)"), "icon" => "hi hi-time", "sub" => array( array( "name" => getMenuLabel("Create a Trigger"), "url" => "new_trigger.php" ), array( "name" => getMenuLabel("View Triggers (Actions)"), "url" => "view_trigger.php" ), array( "name" => getMenuLabel("Trigger Notification Email"), "url" => "new_notification.php" ) ) );
    $trigger_stats_menu = array( "name" => getMenuLabel("Trigger Stats"), "url" => "view_stats_triggers.php" );
    $autoresp_menu = array( "name" => getMenuLabel("Autoresponders"), "icon" => "fa fa-bullhorn", "sub" => array( array( "name" => getMenuLabel("Create an Autoresponder"), "url" => "new_autoresponders.php" ), array( "name" => getMenuLabel("View Autoresponders"), "url" => "view_autoresponders.php" ), array( "name" => getMenuLabel("Create Autoresponders Group"), "url" => "new_autoresponders_group.php" ), array( "name" => getMenuLabel("View Autoresponders Groups"), "url" => "view_autoresponders_group.php" ), array( "name" => getMenuLabel("Create Sending Criteria"), "url" => "new_autoresponders_criteria.php" ), array( "name" => getMenuLabel("View Sending Criteria"), "url" => "view_autoresponders_criteria.php" ) ) );
    $autoresp_stats_menu = array( "name" => getMenuLabel("Autoresponder Stats"), "url" => "view_stats_autoresponder.php" );
    $autoresp_group_stats_menu = array( "name" => getMenuLabel("Auto Responder Group Stats"), "url" => "view_stats_autoresponder_group.php" );
    $subuseracc_menu = array( "name" => getMenuLabel("Sub User Accounts"), "icon" => "fa fa-user", "sub" => array( array( "name" => getMenuLabel("Create a Sub User Role"), "url" => "new_sub_user_role.php" ), array( "name" => getMenuLabel("View Sub User Roles"), "url" => "view_sub_user_role.php" ), array( "name" => getMenuLabel("Create a Sub User"), "url" => "new_sub_user_account.php" ), array( "name" => getMenuLabel("View Sub Users"), "url" => "view_sub_user_account.php" ) ) );
    $useracc_menu = array( "hide_permission" => 1, "name" => getMenuLabel("User Management"), "icon" => "fa fa-users", "sub" => array( array( "name" => getMenuLabel("Create a User Role"), "url" => "new_user_role.php" ), array( "name" => getMenuLabel("View User Roles"), "url" => "view_user_role.php" ), array( "name" => getMenuLabel("Create a User"), "url" => "new_user_account.php" ), array( "name" => getMenuLabel("View Users"), "url" => "view_user_account.php" ), array( "name" => getMenuLabel("Add Email Credits"), "url" => "new_credit_addons.php" ) ) );
    $splittest_menu1 = array( "name" => getMenuLabel("Create a Split Test"), "url" => "new_email_split_campaign.php" );
    $splittest_menu2 = array( "name" => getMenuLabel("View Split Tests"), "url" => "view_email_split_campaign.php" );
    $splittest_stats_menu = array( "name" => getMenuLabel("Split Test Stats"), "url" => "view_stats_split_campaign.php" );
    $domainmask_menu = array( "name" => getMenuLabel("Domain Masking"), "icon" => "fa fa-sitemap", "sub" => array( array( "name" => getMenuLabel("Setup Domain Masking"), "url" => "new_mask_domain.php" ), array( "name" => getMenuLabel("View all Masked Domains"), "url" => "view_mask_domain.php" ) ) );
    if( $PRODUCTNAME == "MUMARAESP" ) 
    {
        $smtp_menu = array( "name" => getMenuLabel("SMTP Accounts"), "icon" => "fa fa-lock", "sub" => array( array( "name" => getMenuLabel("Setup an SMTP Account"), "url" => "new_smtp.php" ), array( "name" => getMenuLabel("View all SMTP Accounts"), "url" => "view_smtp.php" ) ) );
        $esp_menu = array( "hide_permission" => 1, "name" => getMenuLabel("ESP Setting"), "icon" => "fa fa-lock", "sub" => array( array( "name" => getMenuLabel("Server Preference"), "url" => "esp_setup.php" ), array( "name" => getMenuLabel("Create Sending Server"), "url" => "new_esp_server.php" ), array( "name" => getMenuLabel("View Sending Server"), "url" => "view_esp_server.php" ), array( "name" => getMenuLabel("IP Blocks"), "url" => "esp_ip_list.php" ), array( "name" => getMenuLabel("IP Assignment"), "url" => "assing_ip_list.php" ), array( "name" => getMenuLabel("Contacts Importing"), "url" => "contacts_importing.php" ), array( "name" => getMenuLabel("Create Support Agents"), "url" => "new_support_user.php" ), array( "name" => getMenuLabel("View Support Agents"), "url" => "view_support_user.php" ) ) );
        $esp_remote_stat = array( "name" => getMenuLabel("Global Stats"), "url" => "view_stats_sending.php" );
        $multiple_sch_campaing = array( "name" => getMenuLabel("Schedule Multiple Campaigns"), "url" => "multiple_schedule_campaign.php" );
    }
    else
    {
        $smtp_menu = array( "name" => getMenuLabel("SMTP Accounts"), "icon" => "fa fa-lock", "sub" => array( array( "name" => getMenuLabel("Setup SMTP Account"), "url" => "new_smtp.php" ), array( "name" => getMenuLabel("View SMTP Accounts"), "url" => "view_smtp.php" ), array( "name" => getMenuLabel("Import SMTP Accounts"), "url" => "import_smtp.php" ), array( "name" => getMenuLabel("Black Lists"), "url" => "blacklist_checker.php" ) ) );
        $esp_remote_stat = $esp_menu = array(  );
        $multiple_sch_campaing = array( "name" => getMenuLabel("Schedule Multiple Campaigns"), "url" => "multiple_schedule_campaign.php" );
    }

    if( $PRODUCTNAME == "MUMARAESP" && $_SESSION["primary_admin"] != 1 ) 
    {
        $sender_menu = array( "name" => getMenuLabel("Add Sender Information"), "url" => "new_sender_info.php", "icon" => "fa fa-user" );
        array_push($_SESSION["role_permissions"], "new_sender_info.php");
    }
    else
    {
        $sender_menu = array(  );
    }

    $primary_nav = array( array( "name" => getMenuLabel("Dashboard"), "url" => "index.php", "icon" => "gi gi-stopwatch" ), $sender_menu, array( "name" => getMenuLabel("My Lists"), "icon" => "gi gi-notes_2", "sub" => array( array( "name" => getMenuLabel("Create a List"), "url" => "new_list.php" ), array( "name" => getMenuLabel("View all Lists"), "url" => "view_lists.php" ), array( "name" => getMenuLabel("Create Custom Fields"), "url" => "new_custom_fields.php" ), array( "name" => getMenuLabel("View Custom Fields"), "url" => "view_custom_fields.php" ), array( "name" => getMenuLabel("Segmentation"), "url" => "view_list_segments.php" ), array( "name" => getMenuLabel("View Segments"), "url" => "view_scheduled_segments.php" ), array( "name" => getMenuLabel("Emails Suppression"), "url" => "import_suppressed_contacts.php" ), array( "name" => getMenuLabel("Domains Suppression"), "url" => "suppress_domain.php" ), array( "name" => getMenuLabel("IP(s) Suppression"), "url" => "suppress_ip.php" ) ) ), array( "name" => getMenuLabel("Subscribers"), "icon" => "gi gi-envelope", "sub" => array( array( "name" => getMenuLabel("Add a Subscriber"), "url" => "new_contacts.php" ), array( "name" => getMenuLabel("View all Subscribers"), "url" => "view_contacts.php" ), array( "name" => getMenuLabel("Delete Subscribers"), "url" => "delete_contacts.php" ), array( "name" => getMenuLabel("Import Subscribers from a File"), "url" => "import_contacts.php" ), array( "name" => getMenuLabel("Export Subscribers to a File"), "url" => "export_contacts.php" ), array( "name" => "Bulk Subscribers Update", "url" => "bulk_subscriber_update.php" ) ) ), array( "name" => getMenuLabel("My Campaigns"), "icon" => "fa fa-exchange", "sub" => array( array( "name" => getMenuLabel("Create an Email Campaign"), "url" => "new_campaign.php" ), array( "name" => getMenuLabel("View all Email Campaigns"), "url" => "view_campaign.php" ), array( "name" => getMenuLabel("Schedule an Email Campaign"), "url" => "schedule_campaign.php" ), $multiple_sch_campaing, array( "name" => getMenuLabel("View Scheduled Campaigns"), "url" => "view_schedule_campaign.php" ), array( "name" => getMenuLabel("Schedule Evergreen Campaign"), "url" => "schedule_evergreen_campaign.php" ), array( "name" => getMenuLabel("View Evergreen Campaigns"), "url" => "view_schedule_evergreen_campaign.php" ), $splittest_menu1, $splittest_menu2 ) ), $autoresp_menu, $trigger_menu, array( "name" => getMenuLabel("Dynamic Content"), "icon" => "fa fa-list-alt fa-fw", "sub" => array( array( "name" => getMenuLabel("Create a Dynamic Content Tag"), "url" => "new_dynamic_content_tag.php" ), array( "name" => getMenuLabel("View all Dynamic Content Tags"), "url" => "view_dynamic_content_tag.php" ) ) ), $spintag_menu, array( "name" => getMenuLabel("Image/File Manager"), "icon" => "fa fa-picture-o fa-fw", "sub" => array( array( "name" => getMenuLabel("Add a File or Image"), "url" => "image_upload.php" ), array( "name" => getMenuLabel("View Gallery"), "url" => "image_view.php" ) ) ), array( "name" => getMenuLabel("Website Forms"), "icon" => "fa fa-list-alt fa-fw", "sub" => array( array( "name" => getMenuLabel("Create a Web Form"), "url" => "new_web_forms.php" ), array( "name" => getMenuLabel("View Web Forms"), "url" => "view_web_forms.php" ) ) ), array( "name" => getMenuLabel("Statistics"), "icon" => "gi gi-charts", "sub" => array( array( "name" => getMenuLabel("Email Campaign Stats"), "url" => "view_stats_schedule_campaign.php" ), $adk_stats_menu, $autoresp_stats_menu, $autoresp_group_stats_menu, $trigger_stats_menu, $splittest_stats_menu, $esp_remote_stat, array( "name" => getMenuLabel("Notification Email"), "url" => "schedule_campaign_notification.php" ) ) ), array( "name" => getMenuLabel("Bounce"), "icon" => "gi gi-message_in", "sub" => array( array( "name" => getMenuLabel("Configure a Bounce Email"), "url" => "new_bounce.php" ), array( "name" => getMenuLabel("View Bounce Emails"), "url" => "view_bounce.php" ), array( "name" => getMenuLabel("Bounce Reasons"), "url" => "new_bounce_reasons.php" ), array( "name" => getMenuLabel("View Bounce Reasons"), "url" => "view_bounce_reasons.php" ) ) ), $fbl_menu, $smtp_menu, $domainmask_menu, array( "name" => getMenuLabel("Email Templates"), "icon" => "gi gi-brush", "sub" => array( array( "name" => getMenuLabel("Create an Email Template"), "url" => "new_email_template.php" ), array( "name" => getMenuLabel("View all Email Templates"), "url" => "view_email_template.php" ) ) ), array( "name" => getMenuLabel("Integrations"), "icon" => "fa fa-cogs", "sub" => array( $mumara_api, $adk_menu, $mandrill_menu, $dropbox_integration_menu, $pmta_integration_menu ) ), $subuseracc_menu, $useracc_menu, array( "hide_permission" => 1, "name" => getMenuLabel("Settings"), "icon" => "gi gi-settings", "sub" => array( array( "name" => getMenuLabel("License Key"), "url" => "license_update.php" ), array( "name" => getMenuLabel("Application Settings"), "url" => "application_settings.php" ), array( "name" => getMenuLabel("Activity Log"), "url" => "activity_log.php" ), array( "name" => getMenuLabel("Custom Headers"), "url" => "custom_header.php" ), $multithread_menu, array( "name" => getMenuLabel("Email Notification Templates"), "url" => "email_templates_list.php" ), array( "name" => getMenuLabel("Notifications SMTP"), "url" => "notification_smtp.php" ), array( "name" => getMenuLabel("Cron Settings"), "url" => "cron_settings.php" ), $whitelabel_menu ) ), $esp_menu, array( "hide_permission" => 1, "name" => getMenuLabel("Tools"), "icon" => "fa fa-wrench", "sub" => array( array( "name" => getMenuLabel("Cron Status"), "url" => "cron_status.php" ), array( "name" => getMenuLabel("Check Permissions"), "url" => "check_files_permissions.php" ), array( "name" => getMenuLabel("Upgrade Version"), "url" => "upgrade.php" ), $auto_backup ) ) );
}
