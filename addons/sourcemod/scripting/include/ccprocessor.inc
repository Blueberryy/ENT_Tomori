#if defined _ccprocessor_included
 #endinput
#endif
#define _ccprocessor_included

#define STATUS_LENGTH   	16
#define TEAM_LENGTH     	64
#define PREFIX_LENGTH   	64
#define NAME_LENGTH     	128
#define MESSAGE_LENGTH  	256
#define MAX_LENGTH      	512


/* 
API key:
	The value changes if the API has been changed. 
	This is a measure against users who do not follow the changes and do not understand what is happening.

	ATTENTION: Do not change it yourself if you are not ready for the consequences!
*/

#define API_KEY 			57531080

#if !defined CORE
	#define API_OOD 		"The plugin module uses an outdated API. You must update it."
#endif

// Message type
enum
{
	eMsg_TEAM = 0,
	eMsg_ALL,
	eMsg_CNAME,

	/* The bind '{MSG}' is not called for this type*/
	eMsg_RADIO,	

	eMsg_SERVER,
	
	eMsg_MAX
};

enum
{
	BIND_PROTOTYPE = 0,

	BIND_STATUS,
	BIND_TEAM,

	BIND_PREFIX_CO,
	BIND_PREFIX,

	BIND_NAME_CO,
	BIND_NAME,

	BIND_MSG_CO,
	BIND_MSG,

	BIND_MAX
};

stock const char szBinds[BIND_MAX][] = 
{
	"{PROTOTYPE}",
	
	"{STATUS}", "{TEAM}", "{PREFIXCO}", "{PREFIX}",
	"{NAMECO}", "{NAME}", "{MSGCO}", 	"{MSG}"
};

/*
 *	Skip colors in an unprepared message
 *
 *	@param iClient		Client index
 *
 * 	@return				true - skipping / false - otherwise
*/
forward bool cc_proc_SkipColorsInMsg(int iClient);

/*
 *	Calls when building parts of the prototype
 *
 *	@param iClient		Client index
 *	@param &pLevel		Replacement priority
 *	@param szBind		Core binds ({PROTOTYPE}, {STATUS}, {TEAM}, {PREFIXCO}, {PREFIX}, {NAMECO}, {NAME}, {MSGCO}, {MSG})
 *	@param szBuffer		Buffer with value
 *	@param iSize		Size of buffer
 *
 * 	@noreturn
*/
forward void cc_proc_RebuildString(int iClient, int &pLevel, const char[] szBind, char[] szBuffer, int iSize);

/*
 *	Streaming output for editing the recipient list
 *
 *	@param iClient		Real sender index
 *  @param clients[]	Recipient list
 *  @param numClients	Number of recipients

 * 	@noreturn
*/
forward void cc_proc_RebuildClients(int iClient, int[] clients, int &numClients);

/*
 *	Calls when capturing an engine message from the server
 *
 *	@param szMessage			Key of engine message (with symbol[0] = '#')
 *	@param IsPhraseExists		If key of engine message is exists
 *	@param IsTranslated			If key of engine message is translated for LANG_SEVER
 *
 * 	@return					Plugin_Changed	- send message for core processing
								Plugin_Continue - exclude engine message processing
								Plugin_Handled 	- exclude message sending by engine
*/
forward Action cc_proc_OnDefMsg(const char[] szMessage, bool IsPhraseExists, bool IsTranslated);

/*
 *	Calls when the config reading is completed
 *
 *	@noparam
 *
 * 	@noreturn
*/
forward void cc_config_parsed();

/*
 *	Calls before building a message
 *
 *	@param iType		Type of message(see enumiration)
 *
 * 	@noreturn
*/
forward void cc_proc_MsgBroadType(const int iType);

/*
 *	Calls when message is build ended
 *
 *	@param iClient			Sender's index
 *	@param szMessage		Built message
 *
 * 	@noreturn
*/
forward void cc_proc_OnMessageBuilt(int iClient, const char[] szMessage);

/*
 *	Approving the sender's index
 *	Calls when message is ready to send
 *
 *	@param &iClientIndex		Sender's index (<> 0)
 *
 * 	@noreturn
*/
forward void cc_proc_IndexApproval(int &iClientIndex);

/*
 *	Called when action is required on the radio key
 *
 *	@param iClient			Sender's index
 *	@param szRKey			Radio key
 *
 * 	@return					true - restrict, false - otherwise
*/
forward bool cc_proc_RestrictRadio(int iClient, const char[] szRKey);

/*
 *	API hand shake
 *
 *	@param api			API version key
 *
 * 	@noreturn
*/
forward void cc_proc_APIHandShake(const int api);

/*
 *	Get a pallete
 *
 *	@noparam
 *
 * 	@return				List:> Key:Value:Transl
*/
native ArrayList cc_drop_palette();

/*
 *	Removing colors from a string
 *
 *	@param szBuffer		String buffer
 *	@param iSize		Size of string
 *
 * 	@noreturn
*/
native void cc_clear_allcolors(char[] szBuffer, int iSize);

/*
 *	Get the API key used by the core
 *
 *	@noparam 
 *
 * 	@return 		API version key
*/
native int cc_get_APIKey();

/*
 *	API key matching
 *
 *	@param api		API version key
 *
 * 	@return				true - equal / false - otherwise
*/
native bool cc_is_APIEqual(const int api);


stock int BreakPoint(int iBindType, char[] szValue)
{
	static const int iMaxLength[BIND_MAX] = 
	{
		MESSAGE_LENGTH, STATUS_LENGTH, TEAM_LENGTH, 
		STATUS_LENGTH, PREFIX_LENGTH, STATUS_LENGTH, 
		NAME_LENGTH, STATUS_LENGTH, MESSAGE_LENGTH
	};

	if(strlen(szValue) >= iMaxLength[iBindType])
	    szValue[iMaxLength[iBindType]] = 0;

	return iMaxLength[iBindType];
}

#if !defined CORE
public void cc_proc_APIHandShake(const int key)
{
	if(key != API_KEY) SetFailState(API_OOD);
}
#endif

public SharedPlugin __pl_ccprocessor= 
{
	name = "ccprocessor",
	file = "ccprocessor.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ccprocessor_SetNTVOptional()
{
	MarkNativeAsOptional("cc_drop_palette");
	MarkNativeAsOptional("cc_clear_allcolors");
	MarkNativeAsOptional("cc_get_APIKey");
	MarkNativeAsOptional("cc_is_APIEqual");
}
#endif