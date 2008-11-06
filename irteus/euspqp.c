///////////////////////////////////////////////////////////////////////////////
///
/// $Id$
///
/// Copyright (c) 1987- JSK, The University of Tokyo.  All Rights Reserved.
///
/// This software is a collisoin of EusLisp code for robot applications,
/// which has been developed by the JSK Laboratory for the IRT project.
/// For more information on EusLisp and it's application to the robotics,
/// please refer to the following papers.
///
/// Toshihiro Matsui
/// Multithread object-oriented language euslisp for parallel and
///  asynchronous programming in robotics
/// Workshop on Concurrent Object-based Systems,
///  IEEE 6th Symposium on Parallel and Distributed Processing, 1994
///
/// Permission to use this software for educational, research
/// and non-profit purposes, without fee, and without a written
/// agreement is hereby granted to all researchers working on
/// the IRT project at the University of Tokyo, provided that the
/// above copyright notice remains intact.  
///

#pragma init (register_euspqp)

#include "eus.h"

double PQP_Distance(double R1[3][3], double T1[3], void *PQP_Model1,
		    double R2[3][3], double T2[3], void *PQP_Model2,
		    float *P1, float *P2, int qsize);

extern pointer ___euspqp();
static register_euspqp()
{ add_module_initializer("___euspqp", ___euspqp);}

pointer PQPMAKEMODEL(register context *ctx, int n, register pointer *argv)
{
    int addr = PQP_MakeModel();
    return makeint(addr);
}

pointer PQPBEGINMODEL(register context *ctx, int n, register pointer *argv)
{
    int m = (int)argv[0];
    PQP_BeginModel(m>>2);
    return(NIL);
}

pointer PQPENDMODEL(register context *ctx, int n, register pointer *argv)
{
    int m = (int)argv[0];
    PQP_EndModel(m>>2);
    return(NIL);
}

pointer PQPADDTRI(register context *ctx, int n, register pointer *argv)
{
    int m = (int)argv[0];
    float *fv1=argv[1]->c.fvec.fv;
    float *fv2=argv[2]->c.fvec.fv;
    float *fv3=argv[3]->c.fvec.fv;
    int id = (int)argv[4]>>2;
    double dv1[3], dv2[3], dv3[3];
    dv1[0] = fv1[0]; dv1[1] = fv1[1]; dv1[2] = fv1[2]; 
    dv2[0] = fv2[0]; dv2[1] = fv2[1]; dv2[2] = fv2[2]; 
    dv3[0] = fv3[0]; dv3[1] = fv3[1]; dv3[2] = fv3[2];
    #if 0
    printf("#f(%f %f %f), #f(%f %f %f), #f(%f %f %f), %d\n",
	   dv1[0], dv1[1], dv1[2], 
	   dv2[0], dv2[1], dv2[2], 
	   dv3[0], dv3[1], dv3[2], id);
    #endif
    PQP_AddTri(m>>2, dv1, dv2, dv3, id);
    return(NIL);
}

pointer PQPCOLLIDE(register context *ctx, int n, register pointer *argv)
{
    float *fr1=argv[0]->c.ary.entity->c.fvec.fv;
    float *ft1=argv[1]->c.fvec.fv;
    int m1=(int)argv[2];
    float *fr2=argv[3]->c.ary.entity->c.fvec.fv;
    float *ft2=argv[4]->c.fvec.fv;
    int m2=(int)argv[5];
    int flag=(int)argv[6]>>2;
    double dr1[3][3], dr2[3][3], dt1[3], dt2[3];

    /*printf("addr1=0x%x, addr2=0x%x, flag=%d\n", m1>>2, m2>>2, flag);*/
    
    dr1[0][0] = fr1[0]; dr1[0][1] = fr1[1]; dr1[0][2] = fr1[2]; 
    dr1[1][0] = fr1[3]; dr1[1][1] = fr1[4]; dr1[1][2] = fr1[5]; 
    dr1[2][0] = fr1[6]; dr1[2][1] = fr1[7]; dr1[2][2] = fr1[8];
#if 0
    printf("%f %f %f\n %f %f %f\n %f %f %f\n\n",
	   dr1[0][0], dr1[0][1], dr1[0][2], 
	   dr1[1][0], dr1[1][1], dr1[1][2], 
	   dr1[2][0], dr1[2][1], dr1[2][2]);
#endif    
    dt1[0] = ft1[0]; dt1[1] = ft1[1]; dt1[2] = ft1[2];

    /*printf("%f %f %f\n", dt1[0], dt1[1], dt1[2]);*/
    
    dr2[0][0] = fr2[0]; dr2[0][1] = fr2[1]; dr2[0][2] = fr2[2]; 
    dr2[1][0] = fr2[3]; dr2[1][1] = fr2[4]; dr2[1][2] = fr2[5]; 
    dr2[2][0] = fr2[6]; dr2[2][1] = fr2[7]; dr2[2][2] = fr2[8]; 

    dt2[0] = ft2[0]; dt2[1] = ft2[1]; dt2[2] = ft2[2]; 

    return makeint((float)(PQP_Collide(dr1, dt1, m1>>2, dr2, dt2, m2>>2, flag)));
}

pointer PQPDISTANCE(register context *ctx, int n, register pointer *argv)
{
    float *fr1=argv[0]->c.ary.entity->c.fvec.fv;
    float *ft1=argv[1]->c.fvec.fv;
    int m1=(int)argv[2];
    float *fr2=argv[3]->c.ary.entity->c.fvec.fv;
    float *ft2=argv[4]->c.fvec.fv;
    int m2=(int)argv[5];
    float *p1=argv[6]->c.fvec.fv;
    float *p2=argv[7]->c.fvec.fv;
    double dr1[3][3], dr2[3][3], dt1[3], dt2[3];
    int qsize = 2;
    numunion nu;

    if (n == 9) qsize = intval(argv[8]);

    /*printf("addr1=0x%x, addr2=0x%x, flag=%d\n", m1>>2, m2>>2, flag);*/
    
    dr1[0][0] = fr1[0]; dr1[0][1] = fr1[1]; dr1[0][2] = fr1[2]; 
    dr1[1][0] = fr1[3]; dr1[1][1] = fr1[4]; dr1[1][2] = fr1[5]; 
    dr1[2][0] = fr1[6]; dr1[2][1] = fr1[7]; dr1[2][2] = fr1[8];
#if 0
    printf("%f %f %f\n %f %f %f\n %f %f %f\n\n",
	   dr1[0][0], dr1[0][1], dr1[0][2], 
	   dr1[1][0], dr1[1][1], dr1[1][2], 
	   dr1[2][0], dr1[2][1], dr1[2][2]);
#endif    
    dt1[0] = ft1[0]; dt1[1] = ft1[1]; dt1[2] = ft1[2];

    /*printf("%f %f %f\n", dt1[0], dt1[1], dt1[2]);*/
    
    dr2[0][0] = fr2[0]; dr2[0][1] = fr2[1]; dr2[0][2] = fr2[2]; 
    dr2[1][0] = fr2[3]; dr2[1][1] = fr2[4]; dr2[1][2] = fr2[5]; 
    dr2[2][0] = fr2[6]; dr2[2][1] = fr2[7]; dr2[2][2] = fr2[8]; 

    dt2[0] = ft2[0]; dt2[1] = ft2[1]; dt2[2] = ft2[2]; 

    double distance, P1[3], P2[3];
    distance = PQP_Distance(dr1, dt1, (void *)(m1>>2), dr2, dt2, (void *)(m2>>2), P1, P2, qsize);
    p1[0]=P1[0]; p1[1]=P1[1]; p1[2]=P1[2];
    p2[0]=P2[0]; p2[1]=P2[1]; p2[2]=P2[2];
    return (makeflt(distance));
}

pointer ___euspqp(register context *ctx, int n, register pointer *argv)
{
    pointer mod=argv[0];

    defun(ctx, "PQPMAKEMODEL", mod, PQPMAKEMODEL);
    defun(ctx, "PQPBEGINMODEL", mod, PQPBEGINMODEL);
    defun(ctx, "PQPENDMODEL", mod, PQPENDMODEL);
    defun(ctx, "PQPADDTRI", mod, PQPADDTRI);
    defun(ctx, "PQPCOLLIDE", mod, PQPCOLLIDE);
    defun(ctx, "PQPDISTANCE", mod, PQPDISTANCE);
}

///////////////////////////////////////////////////////////////////////////////
///
/// $Id$
///
/// $Log$
/// Revision 1.1  2008-09-18 18:11:00  k-okada
/// add irteus
///
///
///