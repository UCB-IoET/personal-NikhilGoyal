/**
 * This file defines the contrib native C functions. You can access these as
 * storm.n.<function>
 * for example storm.n.hello()
 */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "lrotable.h"
#include "auxmods.h"
#include <platform_generic.h>
#include <string.h>
#include <stdint.h>
#include <interface.h>
#include <stdlib.h>
#include <libstorm.h>
#include <libmsgpack.c>
#include <sys/time.h>


/**
 * This is required for the LTR patch that puts module tables
 * in ROM
 */
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"

//Include some libs as C files into this file
#include "natlib/util.c"
//#include "natlib/svcd.c"
#include "natlib/analog/analog.c"


////////////////// BEGIN FUNCTIONS /////////////////////////////

void playTone(lua_State *L) {
  double tone = 1915;
  double duration = 300;
  long i;
  for (i = 0; i < duration * 1000L; i += tone * 2) {
    /*digitalWrite(BUZZER_PIN, HIGH);
    delayMicroseconds(tone);
    digitalWrite(BUZZER_PIN, LOW);
    delayMicroseconds(tone);*/
   
	struct timeval tv;
	gettimeofday(&tv,NULL);
	unsigned long start = tv.tv_sec*1000000 + tv.tv_usec;
	printf("%d\n", tv.tv_usec);
  }
}

void toggle_pin(lua_State *L) {
	
	int N = luaL_checknumber(L, 1);
	printf("in TOGGLE\n");
	uint32_t *reg_gpio = (uint32_t *)0x400E1004;
	*reg_gpio = 1 << 16;
	uint32_t *reg_oder = (uint32_t *)0x400E1044;
	*reg_oder = 1 << 16;
/*
	if (N == 1) {
		uint32_t *reg_ovr = (uint32_t *)0x400E1054;
		*reg_ovr = 1 << 16;
	}
	else if (N == 0) {
		uint32_t *reg_ovr = (uint32_t *)0x400E1058;
		*reg_ovr = 1 << 16;
	}
*/
	uint32_t *reg_ovr = (uint32_t *)0x400E105C;
	//int code = 1;
	while (1)
	{
		*reg_ovr = 1 << 16;
		//code = (code + 1)%2;
		int i;
		for (i = 0; i < 10000000; i++);
		printf("FI: %d\n");
	}
}

void set_analog(lua_State *L) {
	

printf("ENtered set analog\n");
	uint32_t volatile *reg_gpio = (uint32_t *)0x400E1208;
	*reg_gpio = 1 << 4;

	uint32_t volatile *reg_ster = (uint32_t *)0x400E1268;
	*reg_ster = 1 << 4;

	uint32_t volatile *reg_oder = (uint32_t *)0x400E1248;
	*reg_oder = 1 << 4;

	uint32_t volatile *reg_gfer = (uint32_t *)0x400E12C8;
	*reg_gfer = 1 << 4;
	
	uint32_t volatile *reg_pmr0 = (uint32_t *)0x400E1218;
	*reg_pmr0 = 1 << 4;
	uint32_t volatile *reg_pmr1 = (uint32_t *)0x400E1228;
	*reg_pmr1 = 1 << 4;
	uint32_t volatile *reg_pmr2 = (uint32_t *)0x400E1238;
	*reg_pmr2 = 1 << 4;

	uint32_t volatile *reg_puer = (uint32_t *)0x400E1278;
	*reg_puer = 1 << 4;
	uint32_t volatile *reg_pder = (uint32_t *)0x400E1288;
	*reg_pder = 1 << 4;

}

int contrib_fourth_root_m1000(lua_State *L) //mandatory signature
{
    //Get param 1 from top of stack
    double val = (double) luaL_checknumber(L, 1);

    int i;
    double guess = val / 2;
    double step = val / 4;
    for (i=0;i<20;i++)
    {
        if (guess*guess*guess*guess > val)
            guess -= step;
        else
            guess += step;
        step = step / 2;
    }

    //push back a *1000 fixed point
    lua_pushnumber(L, (int)(guess*1000));
    return 1; //one return value
}


int contrib_run_foobar(lua_State *L)
{
    //Load a symbol "foobar" from global table
    lua_getglobal(L, "foobar"); //this is TOS now
    lua_pushnumber(L, 3); //arg1
    lua_pushnumber(L, 5); //arg2
    lua_call(L, /*args=*/ 2, /*retvals=*/ 1);
    int rv = lua_tonumber(L, -1); //-1 is TOS
    printf("from C, rv is=%d\n", rv);
    return 0; //no return values
}

int contrib_run_run_foobar(lua_State *L)
{
    //Load the contrib_run_foobar symbol
    //Could also have got this by loading global storm table
    //then loading the .n key, then getting the value

    //Note that pushlightfunction is eLua specific
    lua_pushlightfunction(L, contrib_run_foobar);
    lua_call(L, 0, 0);
    return 0;
}

int counter(lua_State *L)
{
    int val = lua_tonumber(L, lua_upvalueindex(1));
    val++;

    //Set upvalue (closure variable)
    lua_pushnumber(L, val);
    lua_replace(L, lua_upvalueindex(1));

    //return it too
    lua_pushnumber(L, val);
    return 1;
}

int contrib_makecounter(lua_State *L)
{
    lua_pushnumber(L, 0); //initial val
    lua_pushcclosure(L, &counter, 1);
    return 1; //return the closure
}

/**
 * Prints out hello world
 *
 * Lua signature: hello() -> nil
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_hello(lua_State *L)
{
    printf("Hello world\n");
    // The number of return values
    return 0;
}

/**
 * Prints out hello world N times, X ticks apart
 *
 * N >= 1
 * Lua signature: helloX(N,X) -> 42
 * Maintainer: Michael Andersen <m.andersen@cs.berkeley.edu>
 */
static int contrib_helloX_tail(lua_State *L);
static int contrib_helloX_entry(lua_State *L)
{
    //First run of the loop, lets configure N and X
    int N = luaL_checknumber(L, 1);
    int X = luaL_checknumber(L, 2);
    int loopcounter = 0;

    //Do our job
    printf ("Hello world\n");

    //We already have these on the top of the stack, but this is
    //how you would push variables you want access to in the continuation
    //Also counting down would be more efficient, but this is an example
    lua_pushnumber(L, loopcounter + 1);
    lua_pushnumber(L, N);
    lua_pushnumber(L, X);
    //Now we want to sleep, and when we are done, invoke helloX_tail with
    //the top 3 values of the stack available as upvalues
    cord_set_continuation(L, contrib_helloX_tail, 3);
    return nc_invoke_sleep(L, X);

    //We can't do anything after a cord_invoke_* call, ever!
}
static int contrib_helloX_tail(lua_State *L)
{
    //Grab our upvalues (state passed to us from the previous func)
    int loopcounter = lua_tonumber(L, lua_upvalueindex(1));
    int N = lua_tonumber(L, lua_upvalueindex(2));
    int X = lua_tonumber(L, lua_upvalueindex(3));

    //Do our job with them
    if (loopcounter < N)
    {
        printf ("Hello world\n");
        //Again, an example, these are already at the top of
        //the stack
        lua_pushnumber(L, loopcounter + 1);
        lua_pushnumber(L, N);
        lua_pushnumber(L, X);
        cord_set_continuation(L, contrib_helloX_tail, 3);
        return nc_invoke_sleep(L, X);
    }
    else
    {
        //Base case, now we do our return
        //We promised to return the number 42
        lua_pushnumber(L, 42);
        return cord_return(L, 1);
    }
}

int svcd_advert_received(lua_State *L) {
	char *pay = luaL_checkstring(L, 1);
	char *srcip = luaL_checkstring(L, 2);
	int srcport = luaL_checknumber(L, 3);
        int pack_result = libmsgpack_mp_unpack(L);
	printf("TOP OF STACK: %d\n", lua_gettop(L));
	printf("%d\n",pack_result);

	lua_pushvalue(L, -1);
    	// stack now contains: -1 => table
    	lua_pushnil(L);
    	// stack now contains: -1 => nil; -2 => table
    	while (lua_next(L, -2))
	    {
		// stack now contains: -1 => value; -2 => key; -3 => table
		// copy the key so that lua_tostring does not modify the original
		lua_pushvalue(L, -2);
		// stack now contains: -1 => key; -2 => value; -3 => key; -4 => table
		const char *key = lua_tostring(L, -1);
		const char *value = lua_tostring(L, -2);
		printf("%s => %s\n", key, value);
		// pop value + copy of key, leaving original key
		lua_pop(L, 2);
		// stack now contains: -1 => key; -2 => table
	    }
    // stack now contains: -1 => table (when lua_next returns 0 it pops the key
    // but does not push anything.)
    // Pop table
    	lua_pop(L, 1);
	struct timeval tv;
gettimeofday(&tv,NULL);
return tv.tv_usec;

	/*printf("%s\n %s\n %d\n", pay, srcip, srcport);

	lua_State *L1 = NULL;
	printf("CAM\n");
	lua_pushstring(L,pay);
	printf("CAM1\n");
	int pack_result = libmsgpack_mp_unpack(L);
		printf("%d\n",pack_result);
	char* new_pay = lua_istable(L, 4);

	lua_getglobal(L,"pack");
	lua_pushstring(L, pay);
	lua_call(L,1,LUA_MULTRET);
	char *new_pay = luaL_checkstring(L,-1);
	printf("%s\n",new_pay);
	return 0;
	lua_getglobal(L, "storm.mp.pack");
	lua_pushstring(L, "kkkkkk"); 
	lua_call(L,1,1);*/
}


////////////////// BEGIN MODULE MAP /////////////////////////////
const LUA_REG_TYPE contrib_native_map[] =
{
    { LSTRKEY( "hello" ), LFUNCVAL ( contrib_hello ) },
    { LSTRKEY( "helloX" ), LFUNCVAL ( contrib_helloX_entry ) },
    { LSTRKEY( "fourth_root"), LFUNCVAL ( contrib_fourth_root_m1000 ) },
    { LSTRKEY( "run_foobar"), LFUNCVAL ( contrib_run_foobar ) },
    { LSTRKEY( "makecounter"), LFUNCVAL ( contrib_makecounter ) },
   { LSTRKEY( "advert_received"), LFUNCVAL ( svcd_advert_received ) },
    { LSTRKEY( "playTone"), LFUNCVAL (playTone ) },
	{ LSTRKEY( "toggle_pin"), LFUNCVAL (toggle_pin ) },
	{ LSTRKEY( "set_analog"), LFUNCVAL (set_analog ) },

    //SVCD_SYMBOLS
    ADCIFE_SYMBOLS

    /* Constants for the Temp sensor. */
    // -- Register address --
    { LSTRKEY( "TMP006_VOLTAGE" ), LNUMVAL(0x00)},
    { LSTRKEY( "TMP006_LOCAL_TEMP" ), LNUMVAL(0x01)},
    { LSTRKEY( "TMP006_CONFIG" ), LNUMVAL(0x02)},
    { LSTRKEY( "TMP006_MFG_ID" ), LNUMVAL(0xFE)},
    { LSTRKEY( "TMP006_DEVICE_ID" ), LNUMVAL(0xFF)},

    // -- Config register values
    { LSTRKEY( "TMP006_CFG_RESET" ), LNUMVAL(0x80)},
    { LSTRKEY( "TMP006_CFG_MODEON" ), LNUMVAL(0x70)},
    { LSTRKEY( "TMP006_CFG_1SAMPLE" ), LNUMVAL(0x00)},
    { LSTRKEY( "TMP006_CFG_2SAMPLE" ), LNUMVAL(0x02)},
    { LSTRKEY( "TMP006_CFG_4SAMPLE" ), LNUMVAL(0x04)},
    { LSTRKEY( "TMP006_CFG_8SAMPLE" ), LNUMVAL(0x06)},
    { LSTRKEY( "TMP006_CFG_16SAMPLE" ), LNUMVAL(0x08)},
    { LSTRKEY( "TMP006_CFG_DRDYEN" ), LNUMVAL(0x01)},
    { LSTRKEY( "TMP006_CFG_DRDY" ), LNUMVAL(0x80)},
    

    //The list must end with this
    { LNILKEY, LNILVAL }
};
