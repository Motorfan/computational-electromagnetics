% Bare bones template for Yee simulation.

clc
clear all

% Simulation related parameters.
IHy = 163;
JHy = 195;
IEz = 164;
JEz = 195;
NMax = 2; NNMax = 200; % Maximum time.
NHW = 40; % One half wave cycle.
Med = 2; % No of different media.
Js = 2; % J-position of the plane wave front.

% Constants.
alpha = 16;
delta = alpha/8;
Cl = 3e8;
f = 2.5e9;
pi = 3.141592654;
e0 = (1e-9) / (36*pi);
u0 = (1e-7) * 4 * pi;
DT = delta / ( 2 * Cl );
TwoPIFDeltaT = 2 * pi * f * DT;

% Data arrays.
CHy = zeros ( IHy, JHy );
REz = zeros ( IEz, JEz );
RaEz = zeros ( IEz, JEz );
Hy = zeros ( IHy, JHy, NNMax );
Ez = zeros ( IEz, JEz, NNMax );
AbsEz = zeros ( IEz, JEz );

% ############ Initialization ##############
fprintf ( 1, 'Initializing' );
fprintf ( 1, '.' );

% Initializing the eta and 1/eta arrays.
fprintf ( 1, '.' );
for i=1:IHy
    for j=1:JHy
        CHy ( i, j ) = DT / ( u0 * Mur ( i-0.5, j ) * delta );
    end
end

fprintf ( 1, '.' );
for i=1:IEz
    for j=1:JEz
        REz ( i, j ) = DT / ( e0 * Epsr ( i-1, j ) * delta );
        RaEz ( i, j ) = ( 1 - ( s(i-1, j) * DT ))/( 1 + ( s(i-1, j) * DT ));
    end
end

% Applying a plane wave.
for i=-15:16
    Ez ( 140+i, :, 1 ) = exp ( -(1/16) * ( i )^2 );
    Hy ( 140+i, :, 1 ) = Ez ( 140+i, :, 1 )/377;
end

fprintf ( 1, 'done.\n' );
% ########## Initialization Complete ############

% ##### 2. Now running the Simulation ######
fprintf ( 1, 'Simulation started... \n', 0 );
for n=0:NNMax-2
    fprintf ( 1, '%g %% \n', (n*100)/NNMax );

    % *** Calculation of Magnetic Field Components ***
    % * Calculation of Hy.
    Hy ( :, :, n+2 ) = Hy ( :, :, n+1 ) + ( CHy .* ( Ez( 2:IHy+1, :, n+1 ) - Ez ( 1:IHy, :, n+1 ) ));
    % ************************************************

    % *** Calculation of Electric Field Components ***
    % * Calculation of Ez.
    Ez ( 2:IEz-1, :, n+2 ) = ( RaEz ( 2:IEz-1, : ) .* Ez( 2:IEz-1, :, n+1 ) ) + ( REz ( 2:IEz-1, : ) .* ( Hy( 2:IEz-1, :, n+2 ) - Hy ( 1:IEz-2, :, n+2 ) ));
end

fprintf ( 1, '100 %% \n' );
fprintf ( 1, 'Simulation complete! \n', 0 );

% Simulation animation.
for i=1:NNMax
    figure (2)
    mesh ( Ez (:, :, i) );
    view (-70, 30)
    zlim ( [-2 2] )
end
