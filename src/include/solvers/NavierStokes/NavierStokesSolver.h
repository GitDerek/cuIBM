#pragma once

#include <types.h>
#include <domain.h>
#include <integrationScheme.h>
#include <io/io.h>
#include <parameterDB.h>
//#include <cusp/precond/smoothed_aggregation.h>
//#include <cusp/precond/diagonal.h>

/**
* Navier-Stokes solver for a rectangular domain.
*/
template <typename memoryType>
class NavierStokesSolver
{
protected:
	parameterDB *paramDB;
	domain      *domInfo;

	coo_matrix<int, real, memoryType>
	     M, Minv, L, A, QT, Q, BN, C;

	array1d<real, memoryType>
	     q, qStar, lambda, rn, H, rhs1, rhs2, bc1, bc2, temp2, temp1, bc[4];

	int  timeStep;
	
	real forceX, forceY;

	/**
	* Methods are defined as virtual when they are redefined in a derived class with the same name.
	*/
	void initialiseArrays(int numQ, int numLambda);
	void initialiseFluxes();
	void initialiseBoundaryArrays();
	void assembleMatrices(); // contains subfunctions to calculate A, QT, BN, QTBNQ

	void generateM();
	virtual void generateL();
	void generateA(int alpha);
	void generateBN();
	virtual void generateQT();
	void generateC();

	virtual void generateRN();
	void generateRNFull(real gamma, real beta, real alpha);
	virtual void generateBC1();
	void generateBC1Full(real alpha);
	virtual void generateBC2();

	void assembleRHS1();
	void assembleRHS2();

	void solveIntermediateVelocity();
	void solvePoisson();
	void projectionStep();

	void updateBoundaryConditions();
	void updateSolverState();
	
	virtual void calculateForce();

public:
	virtual void initialise();
	void stepTime();
	void writeData();
	bool finished();
	static NavierStokesSolver<memoryType>* createSolver(parameterDB &paramDB, domain &dom_info);
	virtual std::string name()
	{
		return "Navier-Stokes";
	}
};
