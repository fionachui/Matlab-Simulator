% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Monte Carlo Simulation of Crash Recovery using Fuzzy Logic  %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Set 1:
% % ICs:
% %   -pitch +/- 60 deg
% %   -roll  +/- 60 deg
% %   -45 < yaw < 45 deg
% %   Notes: weird correlation to failure with positive high roll.
% %   Saved file: 'pitch_60_roll_60.mat'
% 
% % Set 2:
% % ICs:
% %   -pitch +/- 60 deg
% %   -roll  +/- 15 deg
% %   -45 < yaw < 45 deg
% %   Saved file: 'pitch_60_roll_15.mat'
% 
% % For sets 1 and 2:
% %   1000 trials. 
% %   RPM max acceleration 70,000 rpm/s. 
% %   min/max RPM 1000/8000.
% 
% % Set 3:
% %   -pitch +/- 60 deg
% %   -roll  +/- 15 deg
% %   -45 < yaw < 45 deg
% 
% %   RPM max acceleration 27,000 rpm/s, other conditions same. 
% 
% % For all trials:
% %   Thrust coefficient: 8.7e-8
% %   Drag coefficient:   8.7e-9
% %   Friction coefficient: 0.3
% %   Angle error to body rate gain: 15.0
% %   Proportional gains only for body rate control (20 for {p,q}, 2 for {r})
% %   Fuzzy logic output between -1 and 1 
% %       -multiplied by 9.81 for Control.accelRef if TOWARD the wall
% %       -multiplied by 9.81/2 if AWAY from the wall
% 
% 
% % See /Controller/checkrecoverystage.m for recovery stage switch conditions
% % See /Controller/controllerrecovery.m for recovery method
% % See /Results/plot_monte.m for plotting results
% % See /Fuzzy\Logic/initfuzzylogicprocess.m for fuzzy logic parameters
% 
tic
clear all;
global g timeImpact globalFlag
 
ImpactParams = initparams_navi;
 
SimParams.recordContTime = 0;
SimParams.useFaesslerRecovery = 1;%Use Faessler recovery
SimParams.useRecovery = 1; 
SimParams.timeFinal = 2.0;
tStep = 1/200;
 
load('monte_save.mat');
 
IC = initIC;
 
ImpactParams.frictionModel.muSliding = 0.3; % 0.2 - 0.4 possible
ImpactParams.wallLoc = 0.0; % as close as possible so that impact ICs are same as when simulation starts
ImpactParams.wallPlane = 'YZ';
ImpactParams.timeDes = 0.5; % irrelevant
ImpactParams.frictionModel.velocitySliding = 1e-4; % m/s
timeImpact = 10000; % irrelevant

IC = initIC;
Control = initcontrol;
PropState = initpropstate;
Setpoint = initsetpoint;
[Contact, ImpactInfo] = initcontactstructs;
localFlag = initflags; % for contact analysis, irrelevant

% Initialize Fuzzy Logic Process
[FuzzyInfo, PREIMPACT_ATT_CALCSTEPFWD] = initfuzzyinput();


% rotation matrix
ImpactIdentification = initimpactidentification;

xVelocity = rand*1.5 + 0.5;
Control.twist.posnDeriv(1) = xVelocity;  
% Incoming pitch +/- 60 deg, roll +/- 15 deg, incoming yaw -45 to 45 deg
IC.attEuler = [deg2rad(30*(rand-0.5));deg2rad(120*(rand-0.5));deg2rad(90*(rand-0.5))];     %%%

% starts next to the wall 5 meter up
IC.posn = [-0.32; 0; 5];                             
Setpoint.posn(3) = IC.posn(3);                                        
xAcc = 0; %don't change                                                

rotMat = quat2rotmat(angle2quat(-(IC.attEuler(1)+pi),IC.attEuler(2),IC.attEuler(3),'xyz')');
                                               

SimParams.timeInit = 0; 
Setpoint.head = IC.attEuler(3);
Setpoint.time = SimParams.timeInit;
Setpoint.posn(1) = IC.posn(1);
Trajectory = Setpoint;

IC = Monte.IC(2);

k = 1;

Experiment.propCmds = [];
Experiment.manualCmds = [];

globalFlag.experiment.rpmChkpt = zeros(4,1);
globalFlag.experiment.rpmChkptIsPassed = zeros(1,4);

[IC.rpm, Control.u] = initrpm(rotMat, [xAcc;0;0]); %Start with hovering RPM

PropState.rpm = IC.rpm;

% Initialize state and kinematics structs from ICs
[state, stateDeriv] = initstate(IC, xAcc);
[Pose, Twist] = updatekinematics(state, stateDeriv);

% Initialize sensors
Sensor = initsensor(rotMat, stateDeriv, Twist);

% Initialize history 
Hist = inithist(SimParams.timeInit, state, stateDeriv, Pose, Twist, Control, PropState, Contact, localFlag, Sensor);

%% Simulation Loop
for iSim = SimParams.timeInit:tStep:SimParams.timeFinal-tStep
%     display(iSim)    

    %% Update Sensors
    rotMat = quat2rotmat(Pose.attQuat);
    Sensor.accelerometer = (rotMat*[0;0;g] + stateDeriv(1:3) + cross(Twist.angVel,Twist.linVel))/g; %in g's
    Sensor.gyro = Twist.angVel;

    %% Impact Detection    
    [ImpactInfo, ImpactIdentification] = detectimpact(iSim, ImpactInfo, ImpactIdentification,...
                                                      Sensor,Hist.poses,PREIMPACT_ATT_CALCSTEPFWD);
    [FuzzyInfo] = fuzzylogicprocess(iSim, ImpactInfo, ImpactIdentification,...
                                    Sensor, Hist.poses(end), SimParams, Control, FuzzyInfo);

    % Calculate accelref in world frame based on FuzzyInfo.output, estWallNormal
    if sum(FuzzyInfo.InputsCalculated) == 4 && Control.accelRefCalculated == 0;
            Control.accelRef = calculaterefacceleration(FuzzyInfo.output, ImpactIdentification.wallNormalWorld);
            Monte.accelRef = [Monte.accelRef; Control.accelRef'];
            Control.accelRefCalculated = 1;
    end

    %% Control
    if ImpactInfo.firstImpactDetected %recovery control       
%             if SimParams.useFaesslerRecovery == 1  
            Control = checkrecoverystage(Pose, Twist, Control, ImpactInfo);
            [Control] = computedesiredacceleration(Control, Twist);

            % Compute control outputs
            [Control] = controllerrecovery(tStep, Pose, Twist, Control);       
            Control.type = 'recovery';
    else
        Control.recoveryStage = 0;
    end

    %% Propagate Dynamics
    options = getOdeOptions();
    [tODE,stateODE] = ode45(@(tODE, stateODE) dynamicsystem(tODE,stateODE, ...
                                                            tStep,Control.rpm,ImpactParams,PropState.rpm, ...
                                                            Experiment.propCmds),[iSim iSim+tStep],state,options);

    % Reset contact flags for continuous time recording        
    globalFlag.contact = localFlag.contact;


    if SimParams.recordContTime == 0

        [stateDeriv, Contact, PropState] = dynamicsystem(tODE(end),stateODE(end,:), ...
                                                         tStep,Control.rpm,ImpactParams, PropState.rpm, ...
                                                         Experiment.propCmds);        
        if sum(globalFlag.contact.isContact)>0
            Contact.hasOccured = 1;
            if ImpactInfo.firstImpactOccured == 0
                ImpactInfo.firstImpactOccured = 1;
            end
        end

    else      
        % Continuous time recording
        for j = 1:size(stateODE,1)
            [stateDeriv, Contact, PropState] = dynamicsystem(tODE(j),stateODE(j,:), ...
                                                             tStep,Control.rpm,ImpactParams, PropState.rpm, ...
                                                             Experiment.propCmds);            
            if sum(globalFlag.contact.isContact)>0
                Contact.hasOccured = 1;
                if ImpactInfo.firstImpactOccured == 0
                    ImpactInfo.firstImpactOccured = 1;
                end
            end     

            ContHist = updateconthist(ContHist,stateDeriv, Pose, Twist, Control, PropState, Contact, globalFlag, Sensor); 
        end

        ContHist.times = [ContHist.times;tODE];
        ContHist.states = [ContHist.states,stateODE'];    
    end

    localFlag.contact = globalFlag.contact;     
    state = stateODE(end,:)';
    t = tODE(end);
    [Pose, Twist] = updatekinematics(state, stateDeriv);

    %Discrete Time recording @ 200 Hz
    Hist = updatehist(Hist, t, state, stateDeriv, Pose, Twist, Control, PropState, Contact, localFlag, Sensor);

end
%%
Monte = updatemontecarlo(k, IC, Hist, Monte, FuzzyInfo, ImpactInfo, xVelocity);



%% Convert to plottable info
Plot = monte2plot(Monte);
  
%% Generate plottable arrays
Plot = hist2plot(Hist);
close all
animate(0,Hist,'ZX',ImpactParams,timeImpact)
