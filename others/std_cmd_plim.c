#include <stdio.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <malloc.h>

#include "triton.h"
#include "events.h"
#include "ipdb.h"
#include "cli.h"
#include "utils.h"
#include "log.h"
#include "memdebug.h"

static void conf_show_common_help(char * const *fields, int fields_cnt, void *client)
{
	cli_send(client, "conf show common [max-starting|max-sessions] - show common conf\r\n");
}

static void conf_set_common_help(char * const *fields, int fields_cnt, void *client)
{
	cli_send(client, "conf set common [max-starting|max-sessions] <n> - Set common conf\r\n");	
}

static void plim_status_help(char * const *fields, int fields_cnt, void *client)
{
	cli_send(client, "plim status [json] - stats for control sessions\r\n");	
}

static int plim_status_exec(const char *cmd, char * const *f, int f_cnt, void *cli)
{

	if ((f_cnt == 3) && (!strcmp(f[2], "json")) ){
		cli_sendv(cli, "{\"sessions-starting\": %u,", ap_session_stat.starting);	
		cli_sendv(cli, "\"sessions-active\": %u,", ap_session_stat.active);	
		cli_sendv(cli, "\"sessions-finishing\": %u,", ap_session_stat.finishing);		
		cli_sendv(cli, "\"max-starting\": %d,", conf_max_starting);
		cli_sendv(cli, "\"max-sessions\": %d}\r\n", conf_max_sessions);		
	}
	else{
		cli_sendv(cli, "sessions-starting: %u\r\n", ap_session_stat.starting);	
		cli_sendv(cli, "sessions-active: %u\r\n", ap_session_stat.active);	
		cli_sendv(cli, "sessions-finishing: %u\r\n", ap_session_stat.finishing);		
		cli_sendv(cli, "max-starting: %d\r\n", conf_max_starting);
		cli_sendv(cli, "max-sessions: %d\r\n", conf_max_sessions);				
	}
	
	return CLI_CMD_OK;	
}

static int conf_show_common_exec(const char *cmd, char * const *f, int f_cnt, void *cli)
{
	
	cli_send(cli, "sessions:\r\n");
	cli_sendv(cli, "  starting: %u\r\n", ap_session_stat.starting);
	cli_sendv(cli, "  active: %u\r\n", ap_session_stat.active);
	cli_sendv(cli, "  finishing: %u\r\n", ap_session_stat.finishing);


	if (f_cnt != 4)
		return CLI_CMD_SYNTAX;

	if (!strcmp(f[3], "max-starting"))
		cli_sendv(cli, "max-starting: %d\r\n", conf_max_starting);	
	else if (!strcmp(f[3], "max-sessions"))
		cli_sendv(cli, "max-sessions: %d\r\n", conf_max_sessions);
	else
		return CLI_CMD_INVAL;

	return CLI_CMD_OK;	
}
//=============================

static int conf_set_common_exec(const char *cmd, char * const *f, int f_cnt, void *cli)
{

	if (f_cnt != 5)
		return CLI_CMD_SYNTAX;
	
	if (!strcmp(f[3], "max-starting")){		
		conf_max_starting = atoi(f[4]);
		cli_sendv(cli, "OK\r\n");
	}
	else if (!strcmp(f[3], "max-sessions")){	
		conf_max_sessions = atoi(f[4]);
		cli_sendv(cli, "OK\r\n");		
	}
	else
		return CLI_CMD_INVAL;

	return CLI_CMD_OK;
	
}
//==========================


static void init(void)
{
	cli_register_simple_cmd2(conf_show_common_exec, conf_show_common_help, 3, "conf", "show", "common");
	cli_register_simple_cmd2(conf_set_common_exec, conf_set_common_help, 3, "conf", "set", "common");	
	cli_register_simple_cmd2(plim_status_exec, plim_status_help, 2, "plim", "status");
}

DEFINE_INIT(12, init);
