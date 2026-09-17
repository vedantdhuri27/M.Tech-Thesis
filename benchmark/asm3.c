/*
 * ASM3 is a C-file S-function for IAWQ AS Model No 3.  
 *
 * Copyright: Ulf Jeppsson, IEA, Lund University, Lund, Sweden
 *
 * This file has been modified by Xavier Flores-Alsina
 * July, 2010
 * IEA, Lund University, Lund, Sweden
 * 
 */

#define S_FUNCTION_NAME asm3

#include "simstruc.h"
#include <math.h>

#define XINIT   ssGetArg(S,0)
#define PAR	ssGetArg(S,1)
#define V	ssGetArg(S,2)
#define SOSAT	ssGetArg(S,3)
#define TEMPMODEL  ssGetArg(S,4)
#define ACTIVATE  ssGetArg(S,5)


/*
 * mdlInitializeSizes - initialize the sizes array
 */
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumContStates(    S, 20);  /* number of continuous states           */
    ssSetNumDiscStates(    S, 0);   /* number of discrete states             */
    ssSetNumInputs(        S, 21);  /* number of inputs                      */
    ssSetNumOutputs(       S, 24);  /* number of outputs                     */
    ssSetDirectFeedThrough(S, 1);   /* direct feedthrough flag               */
    ssSetNumSampleTimes(   S, 1);   /* number of sample times                */
    ssSetNumSFcnParams(    S, 6);   /* number of input arguments             */
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

for (i = 0; i < 20; i++) {
   x0[i] = mxGetPr(XINIT)[i];
}
}

/*
 * mdlOutputs - compute the outputs
 */

static void mdlOutputs(double *y, double *x, double *u, SimStruct *S, int tid)
{
  double i_NSI, i_NSS, i_NXI, i_NXS, i_NBM, i_SSXI, i_SSXS, i_SSBM, i_SSSTO;
  double tempmodel, activate;

  int i;

i_NSI = mxGetPr(PAR)[28];
i_NSS = mxGetPr(PAR)[29];
i_NXI = mxGetPr(PAR)[30];
i_NXS = mxGetPr(PAR)[31];
i_NBM = mxGetPr(PAR)[32];
i_SSXI = mxGetPr(PAR)[33];
i_SSXS = mxGetPr(PAR)[34];
i_SSBM = mxGetPr(PAR)[35];
i_SSSTO = mxGetPr(PAR)[36]; /* not properly defined in ASM3 report */

tempmodel = mxGetPr(TEMPMODEL)[0];
activate = mxGetPr(ACTIVATE)[0];


   for (i = 0; i < 13; i++) {
      y[i] = x[i];
  }

  y[13] = u[13];  /*  Q */
  
  if (tempmodel < 0.5)                            /* Temp */ 
     y[14] = u[14];                                  
  else 
    y[14] = x[14]; 

  
  /* dummy states, only give outputs if ACTIVATE = 1 */
  if (activate > 0.5) {
      y[15] = x[15];
      y[16] = x[16];
      y[17] = x[17];
      y[18] = x[18];
      y[19] = x[19];
      }
  else if (activate < 0.5) {
      y[15] = 0.0;
      y[16] = 0.0;
      y[17] = 0.0;
      y[18] = 0.0;
      y[19] = 0.0;
      }
  
     y[20] = -x[0]+x[1]+x[2]-24.0/14.0*x[4]-64.0/14.0*x[5]+x[7]+x[8]+x[9]+x[10]+x[11];
     y[21] = i_NSI*x[1]+i_NSS*x[2]+x[3]+x[4]+x[5]+i_NXI*x[7]+i_NXS*x[8]+i_NBM*x[9]+i_NBM*x[11];
     y[22] = 1.0/14.0*x[3]-1.0/14.0*x[5]-x[6];
     y[23] = i_SSXI*x[7]+i_SSXS*x[8]+i_SSBM*x[9]+i_SSSTO*x[10]+i_SSBM*x[11];

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

double k_H, K_X, k_STO, ny_NOX, K_O2, K_NOX, K_S, K_STO, mu_H, K_NH4, K_ALK, b_HO2, b_HNOX, b_STOO2, b_STONOX, mu_A, K_ANH4, K_AO2, K_AALK, b_AO2, b_ANOX;
double f_SI, Y_STOO2, Y_STONOX, Y_HO2, Y_HNOX, Y_A, f_XI, i_NSI, i_NSS, i_NXI, i_NXS, i_NBM, i_SSXI, i_SSXS, i_SSBM, i_SSSTO;
double x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;
double y1, y2, y3, y4, y5, y6, y7, y10, y11, y12;
double z1, z2, z3, z4, z5, z6, z7, z9, z10, z11, z12;
double t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12;
double proc1, proc2, proc3, proc4, proc5, proc6, proc7, proc8, proc9, proc10, proc11, proc12;
double reac1, reac2, reac3, reac4, reac5, reac6, reac7, reac8, reac9, reac10, reac11, reac12, reac13, reac15 ,reac16, reac17, reac18, reac19; 
double vol, SO_sat, T;
double xtemp[20];
double tempmodel;
double SO_sat_temp, KLa_temp;

int i;

k_H = mxGetPr(PAR)[0];
K_X = mxGetPr(PAR)[1];
k_STO = mxGetPr(PAR)[2];
ny_NOX = mxGetPr(PAR)[3];
K_O2 = mxGetPr(PAR)[4];
K_NOX = mxGetPr(PAR)[5];
K_S = mxGetPr(PAR)[6];
K_STO = mxGetPr(PAR)[7];
mu_H = mxGetPr(PAR)[8];
K_NH4 = mxGetPr(PAR)[9];
K_ALK = mxGetPr(PAR)[10];
b_HO2 = mxGetPr(PAR)[11];
b_HNOX = mxGetPr(PAR)[12];
b_STOO2 = mxGetPr(PAR)[13];
b_STONOX = mxGetPr(PAR)[14];
mu_A = mxGetPr(PAR)[15];
K_ANH4 = mxGetPr(PAR)[16];
K_AO2 = mxGetPr(PAR)[17];
K_AALK = mxGetPr(PAR)[18];
b_AO2 = mxGetPr(PAR)[19];
b_ANOX = mxGetPr(PAR)[20];
f_SI = mxGetPr(PAR)[21];
Y_STOO2 = mxGetPr(PAR)[22];
Y_STONOX = mxGetPr(PAR)[23];
Y_HO2 = mxGetPr(PAR)[24];
Y_HNOX = mxGetPr(PAR)[25];
Y_A = mxGetPr(PAR)[26];
f_XI = mxGetPr(PAR)[27];
i_NSI = mxGetPr(PAR)[28];
i_NSS = mxGetPr(PAR)[29];
i_NXI = mxGetPr(PAR)[30];
i_NXS = mxGetPr(PAR)[31];
i_NBM = mxGetPr(PAR)[32];
i_SSXI = mxGetPr(PAR)[33];
i_SSXS = mxGetPr(PAR)[34];
i_SSBM = mxGetPr(PAR)[35];
i_SSSTO = mxGetPr(PAR)[36]; /* not properly defined in ASM3 report */
vol = mxGetPr(V)[0];
SO_sat = mxGetPr(SOSAT)[0];

tempmodel = mxGetPr(TEMPMODEL)[0];

/* temperature compensation */
if (tempmodel < 0.5) {    
   /* Compensation from the temperature at the influent of the reactor */ 
   k_H = k_H*exp((log(k_H/2)/10.0)*(u[14]-20.0));
   
   k_STO = k_STO *exp((log(k_STO /2.5)/10.0)*(u[14]-20.0));
   mu_H = mu_H*exp((log(mu_H/1.0)/10.0)*(u[14]-20.0)); 
   b_HO2 = b_HO2*exp((log(b_HO2/0.1)/10.0)*(u[14]-20.0));
   b_HNOX = b_HNOX*exp((log(b_HNOX/0.05)/10.0)*(u[14]-20.0));
   b_STOO2 = b_STOO2*exp((log(b_STOO2/0.1)/10.0)*(u[14]-20.0));
   b_STONOX = b_STONOX*exp((log(b_STONOX/0.05)/10.0)*(u[14]-20.0));
   
   mu_A = mu_A*exp((log(mu_A/0.35)/10.0)*(u[14]-20.0));
   b_AO2 = b_AO2*exp((log(b_AO2/0.05)/10.0)*(u[14]-20.0));
   b_ANOX = b_ANOX*exp((log(b_ANOX/0.02)/10.0)*(u[14]-20.0));
   
   SO_sat_temp = 0.9997743214*8.0/10.5*(56.12*6791.5*exp(-66.7354 + 87.4755/((u[14]+273.15)/100.0) + 24.4526*log((u[14]+273.15)/100.0))); /* van't Hoff equation */
   KLa_temp = u[20]*pow(1.024, (u[14]-15.0));
}
else {
   /* Compensation from the current temperature in the reactor */
    
   k_H = k_H*exp((log(k_H/2)/10.0)*(x[14]-20.0));
   
   k_STO = k_STO *exp((log(k_STO /2.5)/10.0)*(x[14]-20.0));
   mu_H = mu_H*exp((log(mu_H/1.0)/10.0)*(x[14]-20.0)); 
   b_HO2 = b_HO2*exp((log(b_HO2/0.1)/10.0)*(x[14]-20.0));
   b_HNOX = b_HNOX*exp((log(b_HNOX/0.05)/10.0)*(x[14]-20.0));
   b_STOO2 = b_STOO2*exp((log(b_STOO2/0.1)/10.0)*(x[14]-20.0));
   b_STONOX = b_STONOX*exp((log(b_STONOX/0.05)/10.0)*(x[14]-20.0));
   
   mu_A = mu_A*exp((log(mu_A/0.35)/10.0)*(x[14]-20.0));
   b_AO2 = b_AO2*exp((log(b_AO2/0.05)/10.0)*(x[14]-20.0));
   b_ANOX = b_ANOX*exp((log(b_ANOX/0.02)/10.0)*(x[14]-20.0));
   
   SO_sat_temp = 0.9997743214*8.0/10.5*(56.12*6791.5*exp(-66.7354 + 87.4755/((x[14]+273.15)/100.0) + 24.4526*log((x[14]+273.15)/100.0))); /* van't Hoff equation */
   KLa_temp = u[20]*pow(1.024, (x[14]-15.0));
   
} 


/* note 64.0/14.0 is not exactly equal to 4.57 */
/* note 24.0/14.0 is not exactly equal to 1.71 */

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

T = 0.0001; /* time constant = 0.0001 d = 8.64 s */

for (i = 0; i < 20; i++) {
   if (x[i] < 0)
     xtemp[i] = 0;
   else
     xtemp[i] = x[i];
}


if (u[20] < 0)
     x[0] = fabs(u[20]);


proc1 = k_H*(xtemp[8]/xtemp[9])/(K_X+xtemp[8]/xtemp[9])*xtemp[9];
proc2 = k_STO*xtemp[0]/(K_O2+xtemp[0])*xtemp[2]/(K_S+xtemp[2])*xtemp[9];
proc3 = k_STO*ny_NOX*K_O2/(K_O2+xtemp[0])*xtemp[5]/(K_NOX+xtemp[5])*xtemp[2]/(K_S+xtemp[2])*xtemp[9];
proc4 = mu_H*xtemp[0]/(K_O2+xtemp[0])*xtemp[3]/(K_NH4+xtemp[3])*xtemp[6]/(K_ALK+xtemp[6])*(xtemp[10]/xtemp[9])/(K_STO+xtemp[10]/xtemp[9])*xtemp[9];
proc5 = mu_H*ny_NOX*K_O2/(K_O2+xtemp[0])*xtemp[5]/(K_NOX+xtemp[5])*xtemp[3]/(K_NH4+xtemp[3])*xtemp[6]/(K_ALK+xtemp[6])*(xtemp[10]/xtemp[9])/(K_STO+xtemp[10]/xtemp[9])*xtemp[9];
proc6 = b_HO2*xtemp[0]/(K_O2+xtemp[0])*xtemp[9];
proc7 = b_HNOX*K_O2/(K_O2+xtemp[0])*xtemp[5]/(K_NOX+xtemp[5])*xtemp[9];
proc8 = b_STOO2*xtemp[0]/(K_O2+xtemp[0])*xtemp[10];
proc9 = b_STONOX*K_O2/(K_O2+xtemp[0])*xtemp[5]/(K_NOX+xtemp[5])*xtemp[10];
proc10 = mu_A*xtemp[0]/(K_AO2+xtemp[0])*xtemp[3]/(K_ANH4+xtemp[3])*xtemp[6]/(K_AALK+xtemp[6])*xtemp[11];
proc11 = b_AO2*xtemp[0]/(K_AO2+xtemp[0])*xtemp[11];
proc12 = b_ANOX*K_AO2/(K_AO2+xtemp[0])*xtemp[5]/(K_NOX+xtemp[5])*xtemp[11];

reac1 = x2*proc2+x4*proc4+x6*proc6+x8*proc8+x10*proc10+x11*proc11;
reac2 = f_SI*proc1;
reac3 = x1*proc1-proc2-proc3;
reac4 = y1*proc1+y2*proc2+y3*proc3+y4*proc4+y5*proc5+y6*proc6+y7*proc7+y10*proc10+y11*proc11+y12*proc12;
reac5 = -x3*proc3-x5*proc5-x7*proc7-x9*proc9-x12*proc12;
reac6 = x3*proc3+x5*proc5+x7*proc7+x9*proc9+1.0/Y_A*proc10+x12*proc12;
reac7 = z1*proc1+z2*proc2+z3*proc3+z4*proc4+z5*proc5+z6*proc6+z7*proc7+z9*proc9+z10*proc10+z11*proc11+z12*proc12;
reac8 = f_XI*proc6+f_XI*proc7+f_XI*proc11+f_XI*proc12;
reac9 = -proc1;
reac10 = proc4+proc5-proc6-proc7;
reac11 = Y_STOO2*proc2+Y_STONOX*proc3-1.0/Y_HO2*proc4-1.0/Y_HNOX*proc5-proc8-proc9;
reac12 = proc10-proc11-proc12;
reac13 = t1*proc1+t2*proc2+t3*proc3+t4*proc4+t5*proc5+t6*proc6+t7*proc7+t8*proc8+t9*proc9+t10*proc10+t11*proc11+t12*proc12;

reac15 = 0.0;
reac16 = 0.0;
reac17 = 0.0;
reac18 = 0.0;
reac19 = 0.0;



/* SO2 */ if (u[20] < 0)
          //if (KLa_temp < 0)
             dx[0] = 0;
         else
             dx[0] = 1.0/vol*(u[13]*(u[0]-x[0]))+reac1+u[20]*(SO_sat-x[0]);
             //dx[0] = 1.0/vol*(u[13]*(u[0]-x[0]))+reac1+KLa_temp*(SO_sat_temp-x[0]);

/* Si */     dx[1] = 1.0/vol*(u[13]*(u[1]-x[1]))+reac2;
/* Ss */     dx[2] = 1.0/vol*(u[13]*(u[2]-x[2]))+reac3;
/* Snh4 */   dx[3] = 1.0/vol*(u[13]*(u[3]-x[3]))+reac4;
/* Sn2 */    dx[4] = 1.0/vol*(u[13]*(u[4]-x[4]))+reac5;
/* Snox */   dx[5] = 1.0/vol*(u[13]*(u[5]-x[5]))+reac6;
/* Salk */   dx[6] = 1.0/vol*(u[13]*(u[6]-x[6]))+reac7;
/* Xi */     dx[7] = 1.0/vol*(u[13]*(u[7]-x[7]))+reac8;
/* Xs */     dx[8] = 1.0/vol*(u[13]*(u[8]-x[8]))+reac9;
/* Xbh */    dx[9] = 1.0/vol*(u[13]*(u[9]-x[9]))+reac10;
/* Xsto */   dx[10] = 1.0/vol*(u[13]*(u[10]-x[10]))+reac11;
/* Xba */    dx[11] = 1.0/vol*(u[13]*(u[11]-x[11]))+reac12;
/* TSS */    dx[12] = 1.0/vol*(u[13]*(u[12]-x[12]))+reac13;

/* Flow */   dx[13] = (u[13]-x[13])/T;   //low pass filter for flow, avoid algebraic loops */

/* Flow */   //dx[13] = 0.0; 

/* Temp */   if (tempmodel < 0.5)                
             dx[14] = 0.0;                                  
             else 
             dx[14] = 1.0/vol*(u[13]*(u[14]-x[14]));  


/* dummy states, only dilution at this point */
dx[15] = 1.0/vol*(u[13]*(u[15]-x[15]))+reac15;
dx[16] = 1.0/vol*(u[13]*(u[16]-x[16]))+reac16;
dx[17] = 1.0/vol*(u[13]*(u[17]-x[17]))+reac17;
dx[18] = 1.0/vol*(u[13]*(u[18]-x[18]))+reac18;
dx[19] = 1.0/vol*(u[13]*(u[19]-x[19]))+reac19;



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

