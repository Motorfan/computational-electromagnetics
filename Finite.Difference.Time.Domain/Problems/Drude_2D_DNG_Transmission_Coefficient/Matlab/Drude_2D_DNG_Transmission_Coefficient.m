clc
clear all

% Simulation parameters.
SizeI = 256; % No. of spatial steps in x direction.
SizeJ = 256; % No. of spatial steps in y direction.
PMLw = 80; % Width of PML layer.
SlabLeft = round(SizeJ/3+PMLw); % Location of left end of Slab.
SlabRight = round(2*SizeJ/3+PMLw); % Location of right end of Slab
MaxTime = SizeJ; % No. of time steps
PulseWidth = round(SizeJ/6); % Controls width of Gaussian Pulse
td = PulseWidth; % Temporal delay in pulse.
SnapshotResolution = 1; % Snapshot resolution. 1 is best.
SnapshotInterval = 2; % Amount of time delay between snaps.
% Choice of source.
% 1. Gaussian 2. Sine wave 3. Ricker wavelet
SourceChoice = 1;
SourcePlane = 1; % Is the source a plane wave. 0. = Omni 1. Plane-wave.
SourceLocationX = 50; % X Location of source. Only used for an omni-source.
SourceLocationY = PMLw+10; % Y Location of source.

% Constants.
c = 3e8;
pi = 3.141592654;
e0 = (1e-9)/(36*pi);
u0 = (1e-7)*4*pi;

dt = 0.5e-11;
delta = 3e-3;
Sc = c * dt/delta

l = PulseWidth*delta;
f = c/l
fmax = 1/(2*dt)
w = 2*pi*f;
k0 = w/c; % Free space wave number.
% Ricker wavelet parameters.
if SourceChoice == 3
    fp = f; % Peak frenuency
    dr = PulseWidth*dt*2; % Delay
end
% PML arrays.
PsiEzX = zeros(SizeI, SizeJ+2*PMLw);
PsiEzY = zeros(SizeI, SizeJ+2*PMLw);
PsiHyX = zeros(SizeI, SizeJ+2*PMLw);
PsiHxY = zeros(SizeI, SizeJ+2*PMLw+1);

% PML parameters.
kapp = 1;
a = 0.0008;
sig = 0.04;
% Electric.
kappex = kapp;
kappey = kapp;
aex = a;
aey = a;
sigex = 0;
sigey = sig;
bex = exp(-1*(aex/e0+sigex/(kappex*e0))*dt);
bey = exp(-1*(aey/e0+sigey/(kappey*e0))*dt);
Cex = (bex-1)*sigex/(sigex*kappex+kappex^2*aex);
Cey = (bey-1)*sigey/(sigey*kappey+kappey^2*aey);
% Magnetic.
kappmx = kapp;
kappmy = kapp;
amx = a;
amy = a;
sigmx = 0;
sigmy = u0/e0*sig;
bmx = exp(-1*(amx/u0+sigmx/(kappmx*u0))*dt);
bmy = exp(-1*(amy/u0+sigmy/(kappmy*u0))*dt);
Cmx = (bmx-1)*sigmx/(sigmx*kappmx+kappmx^2*amx);
Cmy = (bmy-1)*sigmy/(sigmy*kappmy+kappmy^2*amy);

% Initialization.
Ez = zeros(SizeI, SizeJ+2*PMLw, 3); % z-component of E-field
Dz = zeros(SizeI, SizeJ+2*PMLw, 3); % z-component of D
Hx = zeros(SizeI, SizeJ+2*PMLw+1, 3); % x-component of H-field
Bx = zeros(SizeI, SizeJ+2*PMLw+1, 3); % x-component of B
Hy = zeros(SizeI, SizeJ+2*PMLw, 3); % y-component of H-field
By = zeros(SizeI, SizeJ+2*PMLw, 3); % y-component of B

% Incident and Transmitted Fields.
Ezi = zeros(MaxTime, 1);
Ezt = zeros(MaxTime, 1);
Eztt = zeros(MaxTime, 1);
x1 = SlabLeft+1; % Position of observation.

% Refractive Index calculations.
Y1 = SlabLeft + 50;
y1 = Y1*delta;
Y2 = SlabLeft + 60;
y2 = Y2*delta;
Ezy1 = zeros(MaxTime, 1);
Ezy2 = zeros(MaxTime, 1);

einf = ones(SizeI,SizeJ+2*PMLw+1);
einf(:,SlabLeft:SlabRight) = 1; % einf(Drude) or er in slab.
uinf = ones(SizeI,SizeJ+2*PMLw+1);
uinf(:,SlabLeft:SlabRight) = 1; % uinf(Drude) or ur in slab.
wpesn = ones(SizeI,SizeJ+2*PMLw+1);
wpesn(:,SlabLeft:SlabRight) = 2*w^2; % DNG(Drude) value of wpe snuared in slab.
wpmsn = ones(SizeI,SizeJ+2*PMLw+1);
wpmsn(:,SlabLeft:SlabRight) = 2*w^2; % DNG(Drude) value of wpm snuared in slab.
ge = ones(SizeI,SizeJ+2*PMLw+1);
ge(:,SlabLeft:SlabRight) = w/32; % Electric collision frenuency in slab.
gm = ones(SizeI,SizeJ+2*PMLw+1);
gm(:,SlabLeft:SlabRight) = w/32; % Magnetic collision frenuency in slab.

a0 = (4*dt^2)./(e0*(4*einf+dt^2*wpesn+2*dt*einf.*ge));
a = (1/dt^2)*a0;
b = (1/(2*dt))*ge.*a0;
c = (e0/dt^2)*einf.*a0;
d = (-1*e0/4).*wpesn.*a0;
e = (1/(2*dt))*e0*einf.*ge.*a0;
am0 = (4*dt^2)./(u0*(4*uinf+dt^2*wpmsn+2*dt*uinf.*gm));
am = (1/dt^2)*am0;
bm = (1/(2*dt))*gm.*am0;
cm = (u0/dt^2)*uinf.*am0;
dm = (-1*u0/4).*wpmsn.*am0;
em = (1/(2*dt))*u0*uinf.*gm.*am0;

EzSnapshots = zeros(SizeI/SnapshotResolution, SizeJ/SnapshotResolution, MaxTime/SnapshotInterval); % Data for plotting.
frame = 1;

np = 1;
n0 = 2;
nf = 3;
linecount = 0;
% Outer loop for time-stepping.
fprintf ( 1, '\rDry run started! \n');
tic
% Test loop for incident field in free space.
for n = 0:MaxTime
    
    % Progress indicator.
    if mod(n,2) == 0
        fprintf(1, repmat('\b',1,linecount));
        linecount = fprintf(1, '%g %%', (n*100)/MaxTime );
    end
    
    % ========================= Bx and Hx =============================
    % Hx Psi array.
    x=1:SizeI;
    y=2:SizeJ+2*PMLw;
    PsiHxY(x,y) = (Cmy/delta)*(-Ez(x,y,n0) + Ez(x,y-1,n0)) + bmy*PsiHxY(x,y);
    % Bx in normal space.
    y=(2+PMLw):((SizeJ+2*PMLw+1)-PMLw-1);
    Bx(x,y,nf) = Bx(x,y,n0) + (-Ez(x,y,n0) + Ez(x,y-1,n0)) * dt/delta;
    if PMLw > 0
        % Bx in lower PML layer.
        y=2:PMLw+1;
        Bx(x,y,nf) = Bx(x,y,n0) + dt*((1/kappmy)*(-Ez(x,y,n0) + Ez(x,y-1,n0)) * 1/delta + PsiHxY(x,y));
        % Bx in upper PML layer.
        y=(SizeJ+2*PMLw+1)-PMLw:(SizeJ+2*PMLw);
        Bx(x,y,nf) = Bx(x,y,n0) + dt*((1/kappmy)*(-Ez(x,y,n0) + Ez(x,y-1,n0)) * 1/delta + PsiHxY(x,y));
    end
    Hx(:,:,nf) = Bx(:,:,nf)./(u0*uinf);
    
    % ========================= By and Hy =============================
    % Hy Psi array.
    x=1:SizeI-1;
    y=1:SizeJ+2*PMLw;
    PsiHyX(x,y) = (Cmx/delta)*(Ez(x+1,y,n0)-Ez(x,y,n0)) + bmx*PsiHyX(x,y);
    PsiHyX(SizeI,y) = (Cmx/delta)*(Ez(1,y,n0)-Ez(SizeI,y,n0)) + bmx*PsiHyX(SizeI,y);
    % By in normal space.
    y=(1+PMLw):(SizeJ+2*PMLw)-PMLw;
    By(x,y,nf) = By(x,y,n0) + (Ez(x+1,y,n0) - Ez(x,y,n0)) * dt/delta;
    By(SizeI,y,nf) = By(SizeI,y,n0) + (Ez(1,y,n0) - Ez(SizeI,y,n0)) * dt/delta; % PBC
    if PMLw > 0
        % By in lower PML layer.
        y=1:PMLw;
        By(x,y,nf) = By(x,y,n0) + dt*((1/kappmx)*(Ez(x+1,y,n0) - Ez(x,y,n0)) * 1/delta + PsiHyX(x,y));
        By(SizeI,y,nf) = By(SizeI,y,n0) + dt*((1/kappmx)*(Ez(1,y,n0) - Ez(SizeI,y,n0)) * 1/delta + PsiHyX(SizeI,y)); % PBC
        % By in upper PML layer.
        y=(SizeJ+2*PMLw)-PMLw+1:(SizeJ+2*PMLw);
        By(x,y,nf) = By(x,y,n0) + dt*((1/kappmx)*(Ez(x+1,y,n0) - Ez(x,y,n0)) * 1/delta + PsiHyX(x,y));
        By(SizeI,y,nf) = By(SizeI,y,n0) + dt*((1/kappmx)*(Ez(1,y,n0) - Ez(SizeI,y,n0)) * 1/delta + PsiHyX(SizeI,y)); % PBC
    end
    Hy(:,:,nf) = By(:,:,nf)./(u0*uinf(:,1:SizeJ+2*PMLw));
    
    % ========================= Dz and Ez =============================
    % Psi arrays.
    x=2:SizeI;
    y=1:SizeJ+2*PMLw;
    PsiEzX(x,y) = (Cex/delta)*(Hy(x,y,nf)-Hy(x-1,y,nf)) + bex*PsiEzX(x,y);
    PsiEzX(1,y) = (Cex/delta)*(Hy(1,y,nf)-Hy(SizeI,y,nf)) + bex*PsiEzX(1,y); % PBC
    PsiEzY(x,y) = (Cey/delta)*(-Hx(x,y+1,nf)+Hx(x,y,nf)) + bey*PsiEzY(x,y);
    PsiEzY(1,y) = (Cey/delta)*(-Hx(1,y+1,nf)+Hx(1,y,nf)) + bey*PsiEzY(1,y); % PBC
    % Dz in Normal Space.
    y=(1+PMLw):((SizeJ+2*PMLw)-PMLw);
    Dz(x,y,nf) = Dz(x,y,n0) + (Hy(x,y,nf)-Hy(x-1,y,nf)-Hx(x,y+1,nf)+Hx(x,y,nf)) * dt/delta;
    Dz(1,y,nf) = Dz(1,y,n0) + (Hy(1,y,nf)-Hy(SizeI,y,nf)-Hx(1,y+1,nf)+Hx(1,y,nf)) * dt/delta; % PBC
    if PMLw > 0
        % Dz in lower PML layer.
        y=1:PMLw;
        Dz(x,y,nf) = Dz(x,y,n0) + dt*(((1/kappex)*(Hy(x,y,nf)-Hy(x-1,y,nf))+(1/kappey)*(-Hx(x,y+1,nf)+Hx(x,y,nf))) * 1/delta + PsiEzX(x,y) + PsiEzY(x,y));
        Dz(1,y,nf) = Dz(1,y,n0) + dt*(((1/kappex)*(Hy(1,y,nf)-Hy(SizeI,y,nf))+(1/kappey)*(-Hx(1,y+1,nf)+Hx(1,y,nf))) * 1/delta + PsiEzX(1,y) + PsiEzY(1,y)); % PBC
        % Dz in upper PML layer.
        y=(SizeJ+2*PMLw)-PMLw+1:(SizeJ+2*PMLw);
        Dz(x,y,nf) = Dz(x,y,n0) + dt*(((1/kappex)*(Hy(x,y,nf)-Hy(x-1,y,nf))+(1/kappey)*(-Hx(x,y+1,nf)+Hx(x,y,nf))) * 1/delta + PsiEzX(x,y) + PsiEzY(x,y));
        Dz(1,y,nf) = Dz(1,y,n0) + dt*(((1/kappex)*(Hy(1,y,nf)-Hy(SizeI,y,nf))+(1/kappey)*(-Hx(1,y+1,nf)+Hx(1,y,nf))) * 1/delta + PsiEzX(1,y) + PsiEzY(1,y)); % PBC
    end
    Ez(:,:,nf) = Dz(:,:,nf)./(e0*einf(:,1:SizeJ+2*PMLw));
    
    % ====================== Source ===================
    if SourcePlane == 1
        x = 1:SizeI;
        y = SourceLocationY;        
    else
        x = SourceLocationX;
        y = SourceLocationY;
    end
    % Source.
    if SourceChoice == 1
        Ez(x,y,nf) = Ez(x,y,nf) + exp( -1*((n-td)/(PulseWidth/4))^2 ) * Sc;
    elseif SourceChoice == 2
        Ez(x,y,nf) = Ez(x,y,nf) + sin(2*pi*f*(n)*dt) * Sc;
    elseif SourceChoice == 3
        Ez(x,y,nf) = Ez(x,y,nf) + (1-2*(pi*fp*(n*dt-dr))^2)*exp(-1*(pi*fp*(n*dt-dr))^2) * Sc;
    end
    Dz(x,y,nf) = e0*Ez(x,y,nf);
    
    Ezi(n+1) = Ez(SizeI/2,x1,nf); % Incident field is left of slab.
    
    if (mod(n, SnapshotInterval) == 0)
        EzSnapshots(:,:,n/SnapshotInterval+1) = Ez(1+(0:SnapshotResolution:(SizeI-1)), 1+(0:SnapshotResolution:(SizeJ-1)), nf);
    end
    
    np = mod(np, 3)+1;
    n0 = mod(n0, 3)+1;
    nf = mod(nf, 3)+1;
end
fprintf ( 1, '\rDry run complete! \n');
% Electric field snapshots.
for i=1:(MaxTime/SnapshotInterval)-1
    
    figure (6)
    mesh ( EzSnapshots (:, :, i) );
    view (4, 4)
    zlim ( [-1 1] )
    %caxis([0 1])
    xlabel ('y-axis')
    ylabel ('x-axis')
    %colorbar
    
%     figure (7)
%     surf ( EzSnapshots (:, :, i) );
%     view (0, 90)
%     zlim ( [-10 10] )
%     %caxis([0 1])
%     xlabel ('y-axis')
%     ylabel ('x-axis')
    %colorbar
    
end
% 
% % Reinitialization of fields for actual simulation.
% Ex = zeros(SIZE, 3); % x-component of E-field
% Hy = zeros(SIZE, 3); % y-component of H-field
% % Actual simulation with scatterer.
% fprintf ( 1, 'Simulation started... \n');
% for n = 0:MaxTime
%     
%     % Progress indicator.
%     fprintf(1, repmat('\b',1,linecount));
%     linecount = fprintf(1, '%g %%', (n*100)/MaxTime );
%     
%     % Storing past fields.
%     Ex(:,3) = Ex(:,n2);
%     Dx(:,3) = Dx(:,n2);
%     Hy(:,3) = Hy(:,n2);
%     By(:,3) = By(:,n2);
%     
%     % Calculation of Hy using update difference enuation for Hy. This is time step n.
%     By(1:SIZE-1,n2) = By(1:SIZE-1,n1) + ( ( Ex(1:SIZE-1,n1) - Ex(2:SIZE,n1) ) * dt/(dz) );
%     Hy(:,n2) = am.*(By(:,n2)-2*By(:,n1)+By(:,3))+bm.*(By(:,n2)-By(:,3))+cm.*(2*Hy(:,n1)-Hy(:,3))+dm.*(2*Hy(:,n1)+Hy(:,3))+em.*(Hy(:,3));
%     
%     % ABC for H at SIZE.
%     Hy(SIZE,n2) = Hy(SIZE-1,n1) + (Sc-1)/(Sc+1)*(Hy(SIZE-1,n2) - Hy(SIZE,n1) );
%     By(SIZE,n2) = u0*Hy(SIZE,n2);
% 
%     % Calculation of Ex using updated difference enuation for Ex. This is time step n+1/2.
%     Dx(2:SIZE,n2) = Dx(2:SIZE, n1) + ( dt/(dz)*(Hy(1:SIZE-1, n2) - Hy(2:SIZE, n2)) );
%     Ex(:,n2) = a.*(Dx(:,n2)-2*Dx(:,n1)+Dx(:,3))+b.*(Dx(:,n2)-Dx(:,3))+c.*(2*Ex(:,n1)-Ex(:,3))+d.*(2*Ex(:,n1)+Ex(:,3))+e.*(Ex(:,3));
%     
%     % ABC for E at 1.
%     Ex(1,n2) = Ex(2,n1) + (Sc-1)/(Sc+1)*(Ex(2,n2) - Ex(2,n1));
%     Dx(1,n2) = e0*Ex(1,n2);
%     
%     % Source.
%     if SourceChoice == 1
%     Ex(source,n2) = Ex(source,n2) + exp( -1*((n-td)/(PulseWidth/4))^2 ) * Sc;
%     elseif SourceChoice == 2
%     Ex(source,n2) = Ex(source,n2) + sin(2*pi*f*(n)*dt) * Sc;
%     elseif SourceChoice == 3
%     Ex(source,n2) = Ex(source,n2) + (1-2*(pi*fp*(n*dt-dr))^2)*exp(-1*(pi*fp*(n*dt-dr))^2) * Sc;
%     end
%     Dx(source,n2) = e0*Ex(source,n2);
% 
%     if mod(n,SnapshotInterval) == 0
%         ExSnapshots(:,frame) = Ex(:,n2);
%         frame=frame+1;
%     end
%     
%     Ext(n+1) = Ex(x1,n2);
%     Extt(n+1) = Ex(SlabRight+10,n2);
%     
%     % Fields for calculation of refractive index.
%     Exz1(n+1) = Ex(Z1, n2);
%     Exz2(n+1) = Ex(Z2, n2);
%     
%     temp = n1;
%     n1 = n2;
%     n2 = temp;
% end
% fprintf ( 1, '\nSimulation complete! \n');
% toc
% % Postprocessing.
% Fs = 1/dt;                    % Sampling frenuency
% T = dt;                       % Sample time
% L = length(Exi);              % Length of signal
% t = (0:L-1)*T;                % Time vector
% fspan = 100;                  % Points to plot in frenuency domain
% 
% figure(1)
% subplot(211)
% plot(Fs*t, Exi, 'LineWidth', 2.0, 'Color', 'b')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Incident Field', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('time', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% figure(2)
% subplot(211)
% plot(Fs*t, Ext, 'LineWidth', 2.0, 'Color', 'b')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Transmitted Field', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('time', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% figure(3)
% subplot(211)
% plot(Fs*t, Extt, 'LineWidth', 2.0, 'Color', 'b')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Transmitted Field Beyond Slab', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('time', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% 
% NFFT = 2^nextpow2(L); % Next power of 2 from length of Exi
% % Incident and Transmitted fields.
% EXI = fft(Exi,NFFT)/L;
% EXT = fft(Ext,NFFT)/L;
% EXTT = fft(Extt,NFFT)/L;
% % Refractive index calculations.
% EXZ1 = fft(Exz1,NFFT)/L;
% EXZ2 = fft(Exz2,NFFT)/L;
% f = Fs/2*linspace(0,1,NFFT/2+1);
% 
% % Plot single-sided amplitude spectrum.
% figure(1)
% subplot(212)
% EXIp = 2*abs(EXI(1:NFFT/2+1));
% plot(f(1:fspan), EXIp(1:fspan), 'LineWidth', 2.0, 'Color', 'r')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Single-Sided Amplitude Spectrum of Exi(t)', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('|EXI(f)|', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% figure(2)
% subplot(212)
% EXTp = 2*abs(EXT(1:NFFT/2+1));
% plot(f(1:fspan), EXTp(1:fspan), 'LineWidth', 2.0, 'Color', 'r')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Single-Sided Amplitude Spectrum of Ext(t)', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('|EXT(f)|', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% figure(3)
% subplot(212)
% EXTTp = 2*abs(EXTT(1:NFFT/2+1));
% plot(f(1:fspan), EXTTp(1:fspan), 'LineWidth', 2.0, 'Color', 'r')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Single-Sided Amplitude Spectrum of Extt(t)', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('|EXT(f)|', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% 
% % Transmission Coefficient.
% figure(4)
% subplot(211)
% TAU = abs(EXT(1:NFFT/2+1)./EXI(1:NFFT/2+1));
% plot(f(1:fspan), TAU(1:fspan), 'LineWidth', 2.0, 'Color', 'b')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Transmission Coefficient', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('|EXT(f)/EXI(f)|', 'FontSize', 11, 'FontWeight', 'b')
% axis([-1 1 -2 2])
% axis 'auto x'
% grid on
% subplot(212)
% plot(f(1:fspan), 1-TAU(1:fspan), 'LineWidth', 2.0, 'Color', 'b')
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Reflection Coefficient', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('1-|EXT(f)/EXI(f)|', 'FontSize', 11, 'FontWeight', 'b')
% axis([-1 1 -2 2])
% axis 'auto x'
% grid on
% 
% % Refractive Index calculations.
% nFDTD = (1/(1i*k0*(z1-z2))).*log(EXZ2(1:NFFT/2+1)./EXZ1(1:NFFT/2+1));
% figure(5)
% subplot(211)
% plot(f(1:fspan), real(nFDTD(1:fspan)), 'LineWidth', 2.0, 'Color', 'b');
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Refractive index re(n)', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11)
% ylabel('re(n)', 'FontSize', 11)
% grid on
% subplot(212)
% plot(f(1:fspan), imag(nFDTD(1:fspan)), 'LineWidth', 2.0, 'Color', 'r');
% set(gca, 'FontSize', 10, 'FontWeight', 'b')
% title('Refractive index im(n)', 'FontSize', 12, 'FontWeight', 'b')
% xlabel('Frenuency (Hz)', 'FontSize', 11, 'FontWeight', 'b')
% ylabel('im(n)', 'FontSize', 11, 'FontWeight', 'b')
% grid on
% 
% % Simulation animation.
% for i=1:frame-1
%     figure (6)
%     % Scatterer boundaries.
%     hold off
%     plot([SlabLeft SlabLeft], [-1 1], 'Color', 'r');
%     hold on
%     plot([SlabRight SlabRight], [-1 1], 'Color', 'r');
%     plot(ExSnapshots(:,i), 'LineWidth', 2.0, 'Color', 'b');
%     set(gca, 'FontSize', 10, 'FontWeight', 'b')
%     axis([0 SIZE -1 1])
%     title('Time Domain Simulation', 'FontSize', 12, 'FontWeight', 'b')
%     xlabel('Spatial step (k)', 'FontSize', 11, 'FontWeight', 'b')
%     ylabel('Electric field (Ex)', 'FontSize', 11, 'FontWeight', 'b')
%     grid on
% end