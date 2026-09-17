/*
 *  SETTLER1D is a C-file S-function for defining a 10 layer settler model.  
 *  can simulate 0, 1 or 10 layers for the solubles by using MODELTYPE
 *  The model is developed for ASM3 variables
 *
 * Copyright: Ulf Jeppsson, IEA, Lund University, Lund, Sweden
 *
 * This file has been modified by Xavier Flores-Alsina
 * July, 2010
 * IEA, Lund University, Lund, Sweden
 */

#define S_FUNCTION_NAME settler1d_asm3

#include "simstruc.h"
#include <math.h>

#define XINIT   ssGetArg(S,0)
#define PAR	ssGetArg(S,1)
#define DIM	ssGetArg(S,2)
#define LAYER	ssGetArg(S,3)
#define TEMPMODEL  ssGetArg(S,4)
#define ACTIVATE  ssGetArg(S,5)
#define PAR_ASM3	ssGetArg(S,6)
#define SETTLER	ssGetArg(S,7)

/*
 * mdlInitializeSizes - initialize the sizes array
 */
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumContStates(    S, 190);   /* number of continuous states           */
    ssSetNumDiscStates(    S, 0);   /* number of discrete states             */
    ssSetNumInputs(        S, 22);   /* number of inputs                      */
    ssSetNumOutputs(       S, 243);  /* number of outputs                     */
    ssSetDirectFeedThrough(S, 1);   /* direct feedthrough flag               */
    ssSetNumSampleTimes(   S, 1);   /* number of sample times                */
    ssSetNumSFcnParams(    S, 8);   /* number of input arguments             */
    ssSetNumRWork(         S, 0);   /* number of real work vector elements   */
    ssSetNumIWork(         S, 0);   /* number of integer work vector elements*/
    ssSetNumPWork(         S, 0);   /* number of pointer work vector elements*/
}

/*
 * mdlInitializeSampleTimes - initialize the sample times array
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
}


/*
 * mdlInitializeConditions - initialize the states
 */
static void mdlInitializeConditions(double *x0, SimStruct *S)
{
int i;

for (i = 0; i < 190; i++) {
   x0[i] = mxGetPr(XINIT)[i];
}

}

/*
 * mdlOutputs - compute the outputs
 */

static void mdlOutputs(double *y, double *x, double *u, SimStruct *S, int tid)
{
  double gamma, gamma_eff;
  double tempmodel;
  double activate;
  int i;

  gamma = x[129]/u[12];
  gamma_eff = x[120]/u[12];

  tempmodel = mxGetPr(TEMPMODEL)[0];
  activate =  mxGetPr(ACTIVATE)[0];

 
     /* underflow */
     /* So */y[0]=x[9]; /* use oxygen in return sludge flow */
     /* Si */y[1]=x[19];
     /* Ss */y[2]=x[29];
     /* Snh*/y[3]=x[39];
     /* Sn2*/y[4]=x[49];
     /* Sal*/y[5]=x[59];
     /* Xi */y[6]=x[69];
     /* Xs */y[7]=x[79];
     /* Xb */y[8]=x[89];
     /* Xst*/y[9]=x[99];
     /* Xba*/y[10]=x[109];
     /* xss*/y[11]=x[119];
     /* TSS*/y[12]=x[129];
     /* Qr*/ y[13]=u[20];                     /* Qr */ 
     
     if (tempmodel < 0.5)                     /* Temp */    
        y[14]=u[14];                                  
     else 
        y[14]=x[139];

     /* Dummy states */
     if (activate > 0.5) {
     /* D1 */y[15]=x[149];
     /* D2 */y[16]=x[159];
     /* D3 */y[17]=x[169];
     /* D4 */y[18]=x[179];
     /* D5 */y[19]=x[189];
     }
     else if (activate < 0.5) {
     /* D1 */y[15]=0;
     /* D2 */y[16]=0;
     /* D3 */y[17]=0;
     /* D4 */y[18]=0;
     /* D5 */y[19]=0;   
     }
     
     /* Qw */y[20]=u[21];                             
     
     /* effluent */
     /* So */y[21]=x[0]; /* use oxygen in effluent flow */
     /* Si */y[22]=x[10];
     /* Ss */y[23]=x[20];
     /* Snh*/y[24]=x[30];
     /* Sn2*/y[25]=x[40];
     /* Sno*/y[26]=x[50];
     /* Sal*/y[27]=x[60];
     /* Xi */y[28]=x[70];
     /* Xs */y[29]=x[80];;
     /* Xb*/ y[30]=x[90];;
     /* Xst*/y[31]=x[100];;
     /* Xba*/y[32]=x[110];;
     /* TSS*/y[33]=x[120];;
     /* Q_e*/y[34]=u[13]-u[20]-u[21];  
     
     if (tempmodel < 0.5)      /* Temp */    
        y[35]=u[14];                                  
     else 
        y[35]=x[130]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[36]=x[140];
     /* D2 */y[37]=x[150];
     /* D3 */y[38]=x[160];
     /* D4 */y[39]=x[170];
     /* D5 */y[40]=x[190];
      }
     else if (activate < 0.5) {
     /* D1 */y[36]=0;
     /* D2 */y[37]=0;
     /* D3 */y[38]=0;
     /* D4 */y[39]=0;
     /* D5 */y[40]=0;
     }
     
     /* internal TSS states */
     /* TSS1 */y[41]=x[120];
     /* TSS2 */y[42]=x[121];
     /* TSS3 */y[43]=x[122];
     /* TSS4 */y[44]=x[123];
     /* TSS5 */y[45]=x[124];
     /* TSS6 */y[46]=x[125];
     /* TSS7 */y[47]=x[126];
     /* TSS8 */y[48]=x[127];
     /* TSS9 */y[49]=x[128];
     /* TSS10*/y[50]=x[129];

     y[51]=gamma;
     y[52]=gamma_eff;
//      
//      //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//
    
     /* So */y[53]=x[0]; /* layer1*/
     /* Si */y[54]=x[10];
     /* Ss */y[55]=x[20];
     /* Snh*/y[56]=x[30];
     /* Sn2*/y[57]=x[40];
     /* Sno*/y[58]=x[50];
     /* Sal*/y[59]=x[60];
     /* Xi */y[60]=x[70];
     /* Xs */y[61]=x[80];
     /* Xb*/ y[62]=x[90];
     /* Xst*/y[63]=x[100];
     /* Xba*/y[64]=x[110];
     /* TSS*/y[65]=x[120];
     
     if (tempmodel < 0.5)  /* Temp */    
        y[66]=u[14];                                  
     else 
        y[66]=x[130]; 
     
     /* dxmmy states */
     if (activate > 0.5) {
     /* D1 */y[67]=x[140];
     /* D2 */y[68]=x[150];
     /* D3 */y[69]=x[160];
     /* D4 */y[70]=x[170];
     /* D5 */y[71]=x[180];
     }
     else if (activate < 0.5) {
     /* D1 */y[67]=0;
     /* D2 */y[68]=0;
     /* D3 */y[69]=0;
     /* D4 */y[70]=0;
     /* D5 */y[71]=0;
     }
    
     //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//
     
     /* So */y[72]=x[1]; /* layer2*/
     /* Si */y[73]=x[11];
     /* Ss */y[74]=x[21];
     /* Snh*/y[75]=x[31];
     /* Sn2*/y[76]=x[41];
     /* Sno*/y[77]=x[51];
     /* Sal*/y[78]=x[61];
     /* Xi */y[79]=x[71];
     /* Xs */y[80]=x[81];
     /* Xb*/ y[81]=x[91];
     /* Xst*/y[82]=x[101];
     /* Xba*/y[83]=x[111];
     /* TSS*/y[84]=x[121];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[85]=u[14];                                  
     else 
        y[85]=x[131]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[86]=x[141];
     /* D2 */y[87]=x[151];
     /* D3 */y[88]=x[161];
     /* D4 */y[89]=x[171];
     /* D5 */y[90]=x[181];
     }
     else if (activate < 0.5) {
     /* D1 */y[86]=0;
     /* D2 */y[87]=0;
     /* D3 */y[88]=0;
     /* D4 */y[89]=0;
     /* D5 */y[90]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[91]=x[2]; /* layer3*/
     /* Si */y[92]=x[12];
     /* Ss */y[93]=x[22];
     /* Snh*/y[94]=x[32];
     /* Sn2*/y[95]=x[42];
     /* Sno*/y[96]=x[52];
     /* Sal*/y[97]=x[62];
     /* Xi */y[98]=x[72];
     /* Xs */y[99]=x[82];
     /* Xb*/ y[100]=x[92];
     /* Xst*/y[101]=x[102];
     /* Xba*/y[102]=x[112];
     /* TSS*/y[103]=x[122];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[104]=u[14];                                  
     else 
        y[104]=x[132]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[105]=x[142];
     /* D2 */y[106]=x[152];
     /* D3 */y[107]=x[162];
     /* D4 */y[108]=x[172];
     /* D5 */y[109]=x[182];
     }
     else if (activate < 0.5) {
     /* D1 */y[105]=0;
     /* D2 */y[106]=0;
     /* D3 */y[107]=0;
     /* D4 */y[108]=0;
     /* D5 */y[109]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[110]=x[3]; /* layer4*/
     /* Si */y[111]=x[13];
     /* Ss */y[112]=x[23];
     /* Snh*/y[113]=x[33];
     /* Sn2*/y[114]=x[43];
     /* Sno*/y[115]=x[53];
     /* Sal*/y[116]=x[63];
     /* Xi */y[117]=x[73];
     /* Xs */y[118]=x[83];
     /* Xb*/ y[119]=x[93];
     /* Xst*/y[120]=x[103];
     /* Xba*/y[121]=x[113];
     /* TSS*/y[122]=x[123];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[123]=u[14];                                  
     else 
        y[123]=x[133]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[124]=x[143];
     /* D2 */y[125]=x[153];
     /* D3 */y[126]=x[163];
     /* D4 */y[127]=x[173];
     /* D5 */y[128]=x[183];
     }
     else if (activate < 0.5) {
     /* D1 */y[124]=0;
     /* D2 */y[125]=0;
     /* D3 */y[126]=0;
     /* D4 */y[127]=0;
     /* D5 */y[128]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[129]=x[4]; /* layer5*/
     /* Si */y[130]=x[14];
     /* Ss */y[131]=x[24];
     /* Snh*/y[132]=x[34];
     /* Sn2*/y[133]=x[44];
     /* Sno*/y[134]=x[54];
     /* Sal*/y[135]=x[64];
     /* Xi */y[136]=x[74];
     /* Xs */y[137]=x[84];
     /* Xb*/ y[138]=x[94];
     /* Xst*/y[139]=x[104];
     /* Xba*/y[140]=x[114];
     /* TSS*/y[141]=x[124];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[142]=u[14];                                  
     else 
        y[142]=x[134]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[143]=x[144];
     /* D2 */y[144]=x[154];
     /* D3 */y[145]=x[164];
     /* D4 */y[146]=x[174];
     /* D5 */y[147]=x[184];
     }
     else if (activate < 0.5) {
     /* D1 */y[143]=0;
     /* D2 */y[144]=0;
     /* D3 */y[145]=0;
     /* D4 */y[146]=0;
     /* D5 */y[147]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[148]=x[5]; /* layer6*/
     /* Si */y[149]=x[15];
     /* Ss */y[150]=x[25];
     /* Snh*/y[151]=x[35];
     /* Sn2*/y[152]=x[45];
     /* Sno*/y[153]=x[55];
     /* Sal*/y[154]=x[65];
     /* Xi */y[155]=x[75];
     /* Xs */y[156]=x[85];
     /* Xb*/ y[157]=x[95];
     /* Xst*/y[158]=x[105];
     /* Xba*/y[159]=x[115];
     /* TSS*/y[160]=x[125];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[161]=u[14];                                  
     else 
        y[161]=x[135]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[162]=x[145];
     /* D2 */y[163]=x[155];
     /* D3 */y[164]=x[165];
     /* D4 */y[165]=x[175];
     /* D5 */y[166]=x[185];
     }
     else if (activate < 0.5) {
     /* D1 */y[162]=0;
     /* D2 */y[163]=0;
     /* D3 */y[164]=0;
     /* D4 */y[165]=0;
     /* D5 */y[166]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[167]=x[6]; /* layer7*/
     /* Si */y[168]=x[16];
     /* Ss */y[169]=x[26];
     /* Snh*/y[170]=x[36];
     /* Sn2*/y[171]=x[46];
     /* Sno*/y[172]=x[56];
     /* Sal*/y[173]=x[66];
     /* Xi */y[174]=x[76];
     /* Xs */y[175]=x[86];
     /* Xb*/ y[176]=x[96];
     /* Xst*/y[177]=x[106];
     /* Xba*/y[178]=x[116];
     /* TSS*/y[179]=x[126];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[180]=u[14];                                  
     else 
        y[180]=x[136]; 
     
     /* dummy states */
      if (activate > 0.5) {
     /* D1 */y[181]=x[146];
     /* D2 */y[182]=x[156];
     /* D3 */y[183]=x[166];
     /* D4 */y[184]=x[176];
     /* D5 */y[185]=x[187];
     }
     else if (activate < 0.5) {
     /* D1 */y[181]=0;
     /* D2 */y[182]=0;
     /* D3 */y[183]=0;
     /* D4 */y[184]=0;
     /* D5 */y[185]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[186]=x[7]; /* layer8*/
     /* Si */y[187]=x[17];
     /* Ss */y[188]=x[27];
     /* Snh*/y[189]=x[37];
     /* Sn2*/y[190]=x[47];
     /* Sno*/y[191]=x[57];
     /* Sal*/y[192]=x[67];
     /* Xi */y[193]=x[77];
     /* Xs */y[194]=x[87];
     /* Xb*/ y[195]=x[97];
     /* Xst*/y[196]=x[107];
     /* Xba*/y[197]=x[117];
     /* TSS*/y[198]=x[127];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[199]=u[14];                                  
     else 
        y[199]=x[137]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[200]=x[147];
     /* D2 */y[201]=x[157];
     /* D3 */y[202]=x[167];
     /* D4 */y[203]=x[177];
     /* D5 */y[204]=x[187];
      }
     else if (activate < 0.5) {
     /* D1 */y[200]=0;
     /* D2 */y[201]=0;
     /* D3 */y[202]=0;
     /* D4 */y[203]=0;
     /* D5 */y[204]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[205]=x[8]; /* layer9*/
     /* Si */y[206]=x[18];
     /* Ss */y[207]=x[28];
     /* Snh*/y[208]=x[38];
     /* Sn2*/y[209]=x[48];
     /* Sno*/y[210]=x[58];
     /* Sal*/y[211]=x[68];
     /* Xi */y[212]=x[78];
     /* Xs */y[213]=x[88];
     /* Xb*/ y[214]=x[98];
     /* Xst*/y[215]=x[108];
     /* Xba*/y[216]=x[118];
     /* TSS*/y[217]=x[128];
     
     if (tempmodel < 0.5)      /* Temp */    
        y[218]=u[14];                                  
     else 
        y[218]=x[138]; 
     
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[219]=x[148];
     /* D2 */y[220]=x[158];
     /* D3 */y[221]=x[168];
     /* D4 */y[222]=x[178];
     /* D5 */y[223]=x[188];
     }
     else if (activate < 0.5) {
     /* D1 */y[219]=0;
     /* D2 */y[220]=0;
     /* D3 */y[221]=0;
     /* D4 */y[222]=0;
     /* D5 */y[223]=0;
     }
     
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
     
     /* So */y[224]=x[9]; /* layer10*/
     /* Si */y[225]=x[19];
     /* Ss */y[226]=x[29];
     /* Snh*/y[227]=x[39];
     /* Sn2*/y[228]=x[49];
     /* Sno*/y[229]=x[59];
     /* Sal*/y[230]=x[69];
     /* Xi */y[231]=x[79];
     /* Xs */y[232]=x[89];
     /* Xb*/ y[233]=x[99];
     /* Xst*/y[234]=x[109];
     /* Xba*/y[235]=x[119];
     /* TSS*/y[236]=x[129];
     if (tempmodel < 0.5)      /* Temp */    
        y[237]=u[14];                                  
     else 
        y[237]=x[139]; 
     /* dummy states */
     if (activate > 0.5) {
     /* D1 */y[238]=x[149];
     /* D2 */y[239]=x[159];
     /* D3 */y[240]=x[169];
     /* D4 */y[241]=x[189];
     /* D5 */y[242]=x[199];
     }
     else if (activate < 0.5) {
     /* D1 */y[238]=0;
     /* D2 */y[239]=0;
     /* D3 */y[240]=0;
     /* D4 */y[241]=0;
     /* D5 */y[242]=0;
     }
     
// //     //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//   
  
}
  
/*
 * mdlUpdate - perform action at major integration time step
 */

static void mdlUpdate(double *x, double *u, SimStruct *S, int tid)
{
}

/*
 * mdlDerivatives - compute the derivatives
 */
static void mdlDerivatives(double *dx, double *x, double *u, SimStruct *S, int tid)
{

double v0_max, v0, r_h, r_p, f_ns, X_t, area, h, feedlayer, volume;
double Q_f, Q_e, Q_u, v_up, v_dn, v_in, eps;
double activate, tempmodel;
double reactive_settler;
int i;
double vs[10];
double Js[11];
double Jstemp[10];
double Jflow[11];

double k_H, K_X, k_STO, ny_NOX, K_O2, K_NOX, K_S, K_STO, mu_H, K_NH4, K_ALK, b_HO2, b_HNOX, b_STOO2, b_STONOX, mu_A, K_ANH4, K_AO2, K_AALK, b_AO2, b_ANOX;
double f_SI, Y_STOO2, Y_STONOX, Y_HO2, Y_HNOX, Y_A, f_XI, i_NSI, i_NSS, i_NXI, i_NXS, i_NBM, i_SSXI, i_SSXS, i_SSBM, i_SSSTO;
double x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;
double y1, y2, y3, y4, y5, y6, y7, y10, y11, y12;
double z1, z2, z3, z4, z5, z6, z7, z9, z10, z11, z12;
double t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12;

double proc1[10], proc2[10], proc3[10], proc4[10], proc5[10], proc6[10], proc7[10], proc8[10], proc9[10], proc10[10], proc11[10], proc12[10];
double reac1[10], reac2[10], reac3[10], reac4[10], reac5[10], reac6[10], reac7[10], reac8[10], reac9[10], reac10[10], reac11[10], reac12[10], reac13[10], reac15[10] ,reac16[10], reac17[10], reac18[10], reac19[10]; 
double k_H_T[10], k_STO_T[10], mu_H_T[10], b_HO2_T[10], b_HNOX_T[10], b_STOO2_T[10], b_STONOX_T[10], mu_A_T[10], b_AO2_T[10], b_ANOX_T[10];

double xtemp[190];


v0_max = mxGetPr(PAR)[0];
v0 = mxGetPr(PAR)[1];
r_h = mxGetPr(PAR)[2];
r_p = mxGetPr(PAR)[3];
f_ns = mxGetPr(PAR)[4];
X_t = mxGetPr(PAR)[5];
area = mxGetPr(DIM)[0];
h = mxGetPr(DIM)[1]/mxGetPr(LAYER)[1];
feedlayer = mxGetPr(LAYER)[0];
volume = area*mxGetPr(DIM)[1];

tempmodel = mxGetPr(TEMPMODEL)[0];
activate = mxGetPr(ACTIVATE)[0];

k_H = mxGetPr(PAR_ASM3)[0];
K_X = mxGetPr(PAR_ASM3)[1];
k_STO = mxGetPr(PAR_ASM3)[2];
ny_NOX = mxGetPr(PAR_ASM3)[3];
K_O2 = mxGetPr(PAR_ASM3)[4];
K_NOX = mxGetPr(PAR_ASM3)[5];
K_S = mxGetPr(PAR_ASM3)[6];
K_STO = mxGetPr(PAR_ASM3)[7];
mu_H = mxGetPr(PAR_ASM3)[8];
K_NH4 = mxGetPr(PAR_ASM3)[9];
K_ALK = mxGetPr(PAR_ASM3)[10];
b_HO2 = mxGetPr(PAR_ASM3)[11];
b_HNOX = mxGetPr(PAR_ASM3)[12];
b_STOO2 = mxGetPr(PAR_ASM3)[13];
b_STONOX = mxGetPr(PAR_ASM3)[14];
mu_A = mxGetPr(PAR_ASM3)[15];
K_ANH4 = mxGetPr(PAR_ASM3)[16];
K_AO2 = mxGetPr(PAR_ASM3)[17];
K_AALK = mxGetPr(PAR_ASM3)[18];
b_AO2 = mxGetPr(PAR_ASM3)[19];
b_ANOX = mxGetPr(PAR_ASM3)[20];
f_SI = mxGetPr(PAR_ASM3)[21];
Y_STOO2 = mxGetPr(PAR_ASM3)[22];
Y_STONOX = mxGetPr(PAR_ASM3)[23];
Y_HO2 = mxGetPr(PAR_ASM3)[24];
Y_HNOX = mxGetPr(PAR_ASM3)[25];
Y_A = mxGetPr(PAR_ASM3)[26];
f_XI = mxGetPr(PAR_ASM3)[27];
i_NSI = mxGetPr(PAR_ASM3)[28];
i_NSS = mxGetPr(PAR_ASM3)[29];
i_NXI = mxGetPr(PAR_ASM3)[30];
i_NXS = mxGetPr(PAR_ASM3)[31];
i_NBM = mxGetPr(PAR_ASM3)[32];
i_SSXI = mxGetPr(PAR_ASM3)[33];
i_SSXS = mxGetPr(PAR_ASM3)[34];
i_SSBM = mxGetPr(PAR_ASM3)[35];
i_SSSTO = mxGetPr(PAR_ASM3)[36]; /* not properly defined in ASM3 report */

/* switching function */

reactive_settler = mxGetPr(SETTLER)[0];


eps = 0.01;
v_in = u[13]/area;
Q_f = u[13];
Q_u = u[20] + u[21];
Q_e = u[13] - Q_u;
v_up = Q_e/area;
v_dn = Q_u/area;

for (i = 0; i < 190; i++) {
   if (x[i] < 0.0)
     xtemp[i] = 0.0;
   else
     xtemp[i] = x[i];
}


/* calculation of the sedimentation velocity for each of the layers */

for (i = 0; i < 10; i++) {
   vs[i] = v0*(exp(-r_h*(xtemp[120+i]-f_ns*u[12]))-exp(-r_p*(xtemp[120+i]-f_ns*u[12])));   /* u[12] = influent SS concentration */
   if (vs[i] > v0_max)     
      vs[i] = v0_max;
   else if (vs[i] < 0.0)
      vs[i] = 0.0;
}

/* calculation of the sludge flux due to sedimentation for each layer */

for (i = 0; i < 10; i++) {
   Jstemp[i] = vs[i]*xtemp[120+i];
}

/* calculation of the sludge flux due to the liquid flow (upflow or downflow, depending on layer) */

for (i = 0; i < 11; i++) {
   if (i < (feedlayer-eps))     
      Jflow[i] = v_up*xtemp[120+i];
   else
      Jflow[i] = v_dn*xtemp[120+i-1];
}

Js[0] = 0.0;
Js[10] = 0.0;
for (i = 0; i < 9; i++) {
   if ((i < (feedlayer-1-eps)) && (xtemp[120+i+1] <= X_t))
      Js[i+1] = Jstemp[i];
   else if (Jstemp[i] < Jstemp[i+1])     
      Js[i+1] = Jstemp[i];
   else
      Js[i+1] = Jstemp[i+1];
}

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//

for (i = 0; i < 10; i++) {

x1 = 1.0-f_SI;
x2 = -1.0+Y_STOO2;
x3 = (-1.0+Y_STONOX)/(64.0/14.0-24.0/14.0);
x4 = 1.0-1.0/Y_HO2;
x5 = (+1.0-1.0/Y_HNOX)/(64.0/14.0-24.0/14.0);
x6 = -1.0+f_XI;
x7 = (f_XI-1.0)/(64.0/14.0-24.0/14.0);
x8 = -1.0;
x9 = -1.0/(64.0/14.0-24.0/14.0);
x10 = -(64.0/14.0)/Y_A+1.0;
x11 = f_XI-1.0;
x12 = (f_XI-1.0)/(64.0/14.0-24.0/14.0);

y1 = -f_SI*i_NSI-(1.0-f_SI)*i_NSS+i_NXS;
y2 = i_NSS;
y3 = i_NSS;
y4 = -i_NBM;
y5 = -i_NBM;
y6 = -f_XI*i_NXI+i_NBM;
y7 = -f_XI*i_NXI+i_NBM;
y10 = -1.0/Y_A-i_NBM;
y11 = -f_XI*i_NXI+i_NBM;
y12 = -f_XI*i_NXI+i_NBM;

z1 = y1/14.0;
z2 = y2/14.0;
z3 = y3/14.0-x3/14.0;
z4 = y4/14.0;
z5 = y5/14.0-x5/14.0;
z6 = y6/14.0;
z7 = y7/14.0-x7/14.0;
z9 = -x9/14.0;
z10 = y10/14.0-1.0/(Y_A*14.0);
z11 = y11/14.0;
z12 = y12/14.0-x12/14.0;

t1 = -i_SSXS;
t2 = Y_STOO2*i_SSSTO;
t3 = Y_STONOX*i_SSSTO;
t4 = i_SSBM-1.0/Y_HO2*i_SSSTO;
t5 = i_SSBM-1.0/Y_HNOX*i_SSSTO;
t6 = f_XI*i_SSXI-i_SSBM;
t7 = f_XI*i_SSXI-i_SSBM;
t8 = -i_SSSTO;
t9 = -i_SSSTO;
t10 = i_SSBM;
t11 = f_XI*i_SSXI-i_SSBM;
t12 = f_XI*i_SSXI-i_SSBM;



/* temperature compensation */
if (tempmodel < 0.5) {    
   /* Compensation from the temperature at the influent of the reactor */ 
   k_H_T[i] = k_H*exp((log(k_H/2)/10.0)*(u[14]-20.0));
   
   k_STO_T[i] = k_STO *exp((log(k_STO /2.5)/10.0)*(u[14]-20.0));
   mu_H_T[i] = mu_H*exp((log(mu_H/1.0)/10.0)*(u[14]-20.0)); 
   b_HO2_T[i] = b_HO2*exp((log(b_HO2/0.1)/10.0)*(u[14]-20.0));
   b_HNOX_T[i] = b_HNOX*exp((log(b_HNOX/0.05)/10.0)*(u[14]-20.0));
   b_STOO2_T[i] = b_STOO2*exp((log(b_STOO2/0.1)/10.0)*(u[14]-20.0));
   b_STONOX_T[i] = b_STONOX*exp((log(b_STONOX/0.05)/10.0)*(u[14]-20.0));
   
   mu_A_T[i] = mu_A*exp((log(mu_A/0.35)/10.0)*(u[14]-20.0));
   b_AO2_T[i] = b_AO2*exp((log(b_AO2/0.05)/10.0)*(u[14]-20.0));
   b_ANOX_T[i] = b_ANOX*exp((log(b_ANOX/0.02)/10.0)*(u[14]-20.0));
}
else {
   /* Compensation from the current temperature in the reactor */
   k_H_T[i] = k_H*exp((log(k_H/2)/10.0)*(x[14]-20.0));
   
   k_STO_T[i] = k_STO *exp((log(k_STO /2.5)/10.0)*(x[140+i]-20.0));
   mu_H_T[i] = mu_H*exp((log(mu_H/1.0)/10.0)*(x[140+ i]-20.0)); 
   b_HO2_T[i] = b_HO2*exp((log(b_HO2/0.1)/10.0)*(x[140 + i]-20.0));
   b_HNOX_T[i] = b_HNOX*exp((log(b_HNOX/0.05)/10.0)*(x[140 + i]-20.0));
   b_STOO2_T[i] = b_STOO2*exp((log(b_STOO2/0.1)/10.0)*(x[140 +i]-20.0));
   b_STONOX_T[i] = b_STONOX*exp((log(b_STONOX/0.05)/10.0)*(x[140 +i]-20.0));
   
   mu_A_T[i] = mu_A*exp((log(mu_A/0.35)/10.0)*(x[140 + i]-20.0));
   b_AO2_T[i] = b_AO2*exp((log(b_AO2/0.05)/10.0)*(x[140 +i]-20.0));
   b_ANOX_T[i] = b_ANOX*exp((log(b_ANOX/0.02)/10.0)*(x[140 +i]-20.0));
} 

proc1[i]=  k_H_T[i]*(xtemp[i+80]/xtemp[i+90])/(K_X+xtemp[i+80]/xtemp[i+90])*xtemp[i+90];
proc2[i] = k_STO_T[i]*xtemp[i]/(K_O2+xtemp[i])*xtemp[i+20]/(K_S+xtemp[i+20])*xtemp[i+90];
proc3[i] = k_STO_T[i]*ny_NOX*K_O2/(K_O2+xtemp[i])*xtemp[i+50]/(K_NOX+xtemp[i+50])*xtemp[i+20]/(K_S+xtemp[i+20])*xtemp[i+90];
proc4[i] = mu_H_T[i]*xtemp[i]/(K_O2+xtemp[i])*xtemp[i+30]/(K_NH4+xtemp[i+30])*xtemp[i+60]/(K_ALK+xtemp[i+60])*(xtemp[i+100]/xtemp[i+90])/(K_STO+xtemp[i+100]/xtemp[i+90])*xtemp[i+90];
proc5[i] = mu_H_T[i]*ny_NOX*K_O2/(K_O2+xtemp[i])*xtemp[i+50]/(K_NOX+xtemp[i+50])*xtemp[i+30]/(K_NH4+xtemp[i+30])*xtemp[i+60]/(K_ALK+xtemp[i+60])*(xtemp[i+100]/xtemp[i+90])/(K_STO+xtemp[i+100]/xtemp[i+90])*xtemp[i+90];
proc6[i] = b_HO2_T[i]*xtemp[i]/(K_O2+xtemp[i])*xtemp[i+90];
proc7[i] = b_HNOX_T[i]*K_O2/(K_O2+xtemp[i])*xtemp[i+50]/(K_NOX+xtemp[i+50])*xtemp[i+90];
proc8[i] = b_STOO2_T[i]*xtemp[i]/(K_O2+xtemp[i])*xtemp[i+100];
proc9[i] = b_STONOX_T[i]*K_O2/(K_O2+xtemp[i])*xtemp[i+50]/(K_NOX+xtemp[i+50])*xtemp[i+100];
proc10[i] = mu_A_T[i]*xtemp[i]/(K_AO2+xtemp[i])*xtemp[i+30]/(K_ANH4+xtemp[i+30])*xtemp[i+60]/(K_AALK+xtemp[i+60])*xtemp[i+110];
proc11[i] = b_AO2_T[i]*xtemp[i]/(K_AO2+xtemp[i])*xtemp[i+110];
proc12[i] = b_ANOX_T[i]*K_AO2/(K_AO2+xtemp[i])*xtemp[i+50]/(K_NOX+xtemp[i+50])*xtemp[i+110];


if (reactive_settler > 0.5) {
 /* So */reac1[i] = x2*proc2[i]+x4*proc4[i]+x6*proc6[i]+x8*proc8[i]+x10*proc10[i]+x11*proc11[i];
 /* Si */reac2[i] = f_SI*proc1[i];
 /* Ss */reac3[i] = x1*proc1[i]-proc2[i]-proc3[i];
/* Snh */reac4[i] = y1*proc1[i]+y2*proc2[i]+y3*proc3[i]+y4*proc4[i]+y5*proc5[i]+y6*proc6[i]+y7*proc7[i]+y10*proc10[i]+y11*proc11[i]+y12*proc12[i];
/* Sn2 */reac5[i] = -x3*proc3[i]-x5*proc5[i]-x7*proc7[i]-x9*proc9[i]-x12*proc12[i];
/* Sno */reac6[i] = x3*proc3[i]+x5*proc5[i]+x7*proc7[i]+x9*proc9[i]+1.0/Y_A*proc10[i]+x12*proc12[i];
/* alk */reac7[i] = z1*proc1[i]+z2*proc2[i]+z3*proc3[i]+z4*proc4[i]+z5*proc5[i]+z6*proc6[i]+z7*proc7[i]+z9*proc9[i]+z10*proc10[i]+z11*proc11[i]+z12*proc12[i];
 /* Xi */reac8[i] = f_XI*proc6[i]+f_XI*proc7[i]+f_XI*proc11[i]+f_XI*proc12[i];
 /* Xs */reac9[i] = -proc1[i];
 /* Xb */reac10[i] = proc4[i]+proc5[i]-proc6[i]-proc7[i];
/* Xst */reac11[i] = Y_STOO2*proc2[i]+Y_STONOX*proc3[i]-1.0/Y_HO2*proc4[i]-1.0/Y_HNOX*proc5[i]-proc8[i]-proc9[i];
 /* Xa */reac12[i] = proc10[i]-proc11[i]-proc12[i];
/* TSS */reac13[i] = t1*proc1[i]+t2*proc2[i]+t3*proc3[i]+t4*proc4[i]+t5*proc5[i]+t6*proc6[i]+t7*proc7[i]+t8*proc8[i]+t9*proc9[i]+t10*proc10[i]+t11*proc11[i]+t12*proc12[i];
 /* D1 */reac15[i]  = 0.0;
 /* D2 */reac16[i]  = 0.0;
 /* D3 */reac17[i]  = 0.0;
 /* D4 */reac18[i]  = 0.0;
 /* D5 */reac19[i]  = 0.0;

}
else if (reactive_settler  < 0.5) { 
 /* So */reac1[i] = 0.0;
 /* Si */reac2[i] = 0.0;
 /* Ss */reac3[i] = 0.0;
/* Snh */reac4[i] = 0.0;
/* Sn2 */reac5[i] = 0.0;
/* Sno */reac6[i] = 0.0;
/* alk */reac7[i] = 0.0;
 /* Xi */reac8[i] = 0.0;
 /* Xs */reac9[i] = 0.0;
 /* Xb */reac10[i] = 0.0;
/* Xst */reac11[i] = 0.0;
 /* Xa */reac12[i] = 0.0;
/* TSS */reac13[i] =  0.0;
 /* D1 */reac15[i]  = 0.0;
 /* D2 */reac16[i]  = 0.0;
 /* D3 */reac17[i]  = 0.0;
 /* D4 */reac18[i]  = 0.0;
 /* D5 */reac19[i]  = 0.0; 

}
}

/* ASM3 model component balances over the layers */
    
/* Sol. comp. S_O2    ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i]     = (-v_up*xtemp[i]    +v_up*xtemp[i+1])/h   +reac1[i];
   else if (i > (feedlayer-eps)) 
      dx[i]     = (v_dn*xtemp[i-1]    -v_dn*xtemp[i])/h    +reac1[i];
   else 
      dx[i]     = (v_in*u[0] -v_up*xtemp[i]    -v_dn*xtemp[i])/h    +reac1[i];
} 
    
/* Sol. comp. S_I     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+10]  = (-v_up*xtemp[i+10] +v_up*xtemp[i+1+10])/h +reac2[i];
   else if (i > (feedlayer-eps)) 
      dx[i+10]  = (v_dn*xtemp[i-1+10] -v_dn*xtemp[i+10])/h +reac2[i];
   else
      dx[i+10]  = (v_in*u[1] -v_up*xtemp[i+10] -v_dn*xtemp[i+10])/h +reac2[i];
}

/* Sol. comp. S_S     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+20]  = (-v_up*xtemp[i+20] +v_up*xtemp[i+1+20])/h +reac3[i];
   else if (i > (feedlayer-eps)) 
      dx[i+20]  = (v_dn*xtemp[i-1+20] -v_dn*xtemp[i+20])/h +reac3[i];
   else
      dx[i+20]  = (v_in*u[2] -v_up*xtemp[i+20] -v_dn*xtemp[i+20])/h +reac3[i];
}

/* Sol. comp. S_NH4     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+30]  = (-v_up*xtemp[i+30] +v_up*xtemp[i+1+30])/h +reac4[i];
   else if (i > (feedlayer-eps)) 
      dx[i+30]  = (v_dn*xtemp[i-1+30] -v_dn*xtemp[i+30])/h +reac4[i];
   else
      dx[i+30]  = (v_in*u[3] -v_up*xtemp[i+30] -v_dn*xtemp[i+30])/h +reac4[i];
}

/* Sol. comp. S_N2     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+40]  = (-v_up*xtemp[i+40] +v_up*xtemp[i+1+40])/h +reac5[i];
   else if (i > (feedlayer-eps)) 
      dx[i+40]  = (v_dn*xtemp[i-1+40] -v_dn*xtemp[i+40])/h +reac5[i];
   else
      dx[i+40]  = (v_in*u[4] -v_up*xtemp[i+40] -v_dn*xtemp[i+40])/h +reac5[i];
}

/* Sol. comp. S_NOX     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+50]  = (-v_up*xtemp[i+50] +v_up*xtemp[i+1+50])/h +reac6[i];
   else if (i > (feedlayer-eps)) 
      dx[i+50]  = (v_dn*xtemp[i-1+50] -v_dn*xtemp[i+50])/h +reac6[i];
   else
      dx[i+50]  = (v_in*u[5] -v_up*xtemp[i+50] -v_dn*xtemp[i+50])/h +reac6[i];
}

/* Sol. comp. S_ALK     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+60]  = (-v_up*xtemp[i+60] +v_up*xtemp[i+1+60])/h +reac7[i];
   else if (i > (feedlayer-eps)) 
      dx[i+60]  = (v_dn*xtemp[i-1+60] -v_dn*xtemp[i+60])/h +reac7[i];
   else
      dx[i+60]  = (v_in*u[6] -v_up*xtemp[i+60] -v_dn*xtemp[i+60])/h +reac7[i];
}

/* Part. comp. X_I    ; ASM3 */
      dx[70] = ((x[70]/x[120])*(-Jflow[0]-Js[1])+(x[71]/x[121])*Jflow[1])/h +reac8[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+70] = ((xtemp[i+70]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+70]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+70]/xtemp[i+1+120])*Jflow[i+1])/h +reac8[i];
   else if (i > (feedlayer-eps)) 
      dx[i+70] = ((xtemp[i+70]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+70]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac8[i];
   else
      dx[i+70] = ((xtemp[i+70]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+70]/xtemp[i-1+120])*Js[i]+v_in*u[7])/h +reac8[i];
   }  

      
/* Part. comp. X_S    ; ASM3 */
      dx[80] = ((x[80]/x[120])*(-Jflow[0]-Js[1])+(x[81]/x[121])*Jflow[1])/h +reac9[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+80] = ((xtemp[i+80]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+80]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+80]/xtemp[i+1+120])*Jflow[i+1])/h +reac9[i];
   else if (i > (feedlayer-eps)) 
      dx[i+80] = ((xtemp[i+80]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+80]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac9[i];
   else
      dx[i+80] = ((xtemp[i+80]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+80]/xtemp[i-1+120])*Js[i]+v_in*u[8])/h +reac9[i];
   }  
     
/* Part. comp. X_BH    ; ASM3 */
      dx[90] = ((x[90]/x[120])*(-Jflow[0]-Js[1])+(x[91]/x[121])*Jflow[1])/h +reac10[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+90] = ((xtemp[i+90]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+90]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+90]/xtemp[i+1+120])*Jflow[i+1])/h +reac10[i];
   else if (i > (feedlayer-eps)) 
      dx[i+90] = ((xtemp[i+90]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+90]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac10[i];
   else
      dx[i+90] = ((xtemp[i+90]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+90]/xtemp[i-1+120])*Js[i]+v_in*u[9])/h +reac10[i];
   }  

/* Part. comp. X_STO    ; ASM3 */
      dx[100] = ((x[100]/x[120])*(-Jflow[0]-Js[1])+(x[101]/x[121])*Jflow[1])/h +reac11[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+100] = ((xtemp[i+100]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+100]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+100]/xtemp[i+1+120])*Jflow[i+1])/h +reac11[i];
   else if (i > (feedlayer-eps)) 
      dx[i+100] = ((xtemp[i+100]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+100]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac11[i];
   else
      dx[i+100] = ((xtemp[i+100]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+100]/xtemp[i-1+120])*Js[i]+v_in*u[10])/h +reac11[i];
   }  
   
/* Part. comp. X_A    ; ASM3 */
      dx[110] = ((x[110]/x[120])*(-Jflow[0]-Js[1])+(x[111]/x[121])*Jflow[1])/h +reac12[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+110] = ((xtemp[i+110]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+110]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+110]/xtemp[i+1+120])*Jflow[i+1])/h +reac12[i];
   else if (i > (feedlayer-eps)) 
      dx[i+110] = ((xtemp[i+110]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+110]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac12[i];
   else
      dx[i+110] = ((xtemp[i+110]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+110]/xtemp[i-1+120])*Js[i]+v_in*u[11])/h +reac12[i];
   }  

/* Part. comp. X_TSS    ; ASM3 */
      dx[120] = ((x[120]/x[120])*(-Jflow[0]-Js[1])+(x[121]/x[121])*Jflow[1])/h +reac13[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+120] = ((xtemp[i+120]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+120]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+120]/xtemp[i+1+120])*Jflow[i+1])/h +reac13[i];
   else if (i > (feedlayer-eps)) 
      dx[i+120] = ((xtemp[i+120]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+120]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac13[i];
   else
      dx[i+120] = ((xtemp[i+120]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+120]/xtemp[i-1+120])*Js[i]+v_in*u[12])/h +reac13[i];
   }  
 
/* Sol. comp. T     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+130]  = (-v_up*xtemp[i+130] +v_up*xtemp[i+1+130])/h ;
   else if (i > (feedlayer-eps)) 
      dx[i+130]  = (v_dn*xtemp[i-1+130] -v_dn*xtemp[i+130])/h ;
   else
      dx[i+130]  = (v_in*u[14] -v_up*xtemp[i+130] -v_dn*xtemp[i+130])/h ;
}

/* Sol. comp. D1     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+140]  = (-v_up*xtemp[i+140] +v_up*xtemp[i+1+140])/h +reac15[i];
   else if (i > (feedlayer-eps)) 
      dx[i+140]  = (v_dn*xtemp[i-1+140] -v_dn*xtemp[i+140])/h +reac15[i];
   else
      dx[i+140]  = (v_in*u[15] -v_up*xtemp[i+140] -v_dn*xtemp[i+140])/h +reac15[i];
}

/* Sol. comp. D2     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+150]  = (-v_up*xtemp[i+150] +v_up*xtemp[i+1+150])/h +reac16[i];
   else if (i > (feedlayer-eps)) 
      dx[i+150]  = (v_dn*xtemp[i-1+150] -v_dn*xtemp[i+150])/h +reac16[i];
   else
      dx[i+150]  = (v_in*u[16] -v_up*xtemp[i+150] -v_dn*xtemp[i+150])/h +reac16[i];
}
   
/* Sol. comp. D3     ; ASM3 */
for (i = 0; i < 10; i++) {
   if (i < (feedlayer-1-eps))
      dx[i+160]  = (-v_up*xtemp[i+160] +v_up*xtemp[i+1+160])/h +reac17[i];
   else if (i > (feedlayer-eps)) 
      dx[i+160]  = (v_dn*xtemp[i-1+160] -v_dn*xtemp[i+160])/h +reac17[i];
   else
      dx[i+160]  = (v_in*u[17] -v_up*xtemp[i+160] -v_dn*xtemp[i+160])/h +reac17[i];
}   

/* Part. comp. D4    ; ASM3 */
      dx[170] = ((x[170]/x[120])*(-Jflow[0]-Js[1])+(x[171]/x[121])*Jflow[1])/h +reac18[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+170] = ((xtemp[i+170]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+170]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+170]/xtemp[i+1+120])*Jflow[i+1])/h +reac18[i];
   else if (i > (feedlayer-eps)) 
      dx[i+170] = ((xtemp[i+170]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+170]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac18[i];
   else
      dx[i+170] = ((xtemp[i+170]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+170]/xtemp[i-1+120])*Js[i]+v_in*u[18])/h +reac18[i];
}  

 /* Part. comp. D5    ; ASM3 */
      dx[180] = ((x[180]/x[120])*(-Jflow[0]-Js[1])+(x[181]/x[121])*Jflow[1])/h +reac19[0];
for (i = 1; i < 10; i++) {
   if (i < (feedlayer-1-eps)) 
      dx[i+180] = ((xtemp[i+180]/xtemp[i+120])*(-Jflow[i]-Js[i+1])+(xtemp[i-1+180]/xtemp[i-1+120])*Js[i]+(xtemp[i+1+180]/xtemp[i+1+120])*Jflow[i+1])/h +reac19[i];
   else if (i > (feedlayer-eps)) 
      dx[i+180] = ((xtemp[i+180]/xtemp[i+120])*(-Jflow[i+1]-Js[i+1])+(xtemp[i-1+180]/xtemp[i-1+120])*(Jflow[i]+Js[i]))/h +reac19[i];
   else
      dx[i+180] = ((xtemp[i+180]/xtemp[i+120])*(-Jflow[i]-Jflow[i+1]-Js[i+1])+(xtemp[i-1+180]/xtemp[i-1+120])*Js[i]+v_in*u[19])/h +reac19[i]; 
}  
   
   
   
}


/*
 * mdlTerminate - called when the simulation is terminated.
 */
static void mdlTerminate(SimStruct *S)
{
}

#ifdef	MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
