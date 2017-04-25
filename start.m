global g timeImpact globalFlag poleRadius

VxImpact = 2.0;

offset = 0.0;%2*0.56*(rand-0.5);
yawImpact = 0; %degrees
pitchImpact =-15; %degrees
rollImpact = 0.0;

poleRadius = 0.15; % meters

% Initialize Fuzzy Logic Process
[FuzzyInfo, PREIMPACT_ATT_CALCSTEPFWD] = initfuzzyinput();

% Initialize Simulation Parameters
ImpactParams = initparams_navi;

SimParams.recordContTime = 0;
SimParams.useFaesslerRecovery = 1;%Use Faessler recovery
SimParams.useRecovery = 1;
SimParams.timeFinal = 0.75;
tStep = 1/200;

ImpactParams.wallLoc = 0.0;
ImpactParams.wallPlane = 'YZ';
ImpactParams.timeDes = 0.5; %Desired time of impact. Does nothing
ImpactParams.frictionModel.muSliding = 0.1;%0.3;
ImpactParams.frictionModel.velocitySliding = 1e-4; %m/s
timeImpact = 10000;
timeStabilized = 10000;

% Initialize Structures
IC = initIC;
Control = initcontrol;
PropState = initpropstate;
Setpoint = initsetpoint;
[Contact, ImpactInfo] = initcontactstructs;
localFlag = initflags;
ImpactIdentification = initimpactidentification;

Control.twist.posnDeriv(1) = VxImpact; %World X Velocity at impact  

IC.attEuler = [deg2rad(rollImpact);...                                  
               deg2rad(pitchImpact);...                                 
               deg2rad(yawImpact)];  
           
IC.posn = [-0.45;offset;2];  

Setpoint.posn(3) = IC.posn(3); 
xAcc = 0;                                                               
rotMat = quat2rotmat(angle2quat(-(IC.attEuler(1)+pi),IC.attEuler(2),IC.attEuler(3),'xyz')');

SimParams.timeInit = 0; % comment out if using getinitworldx()

Setpoint.head = IC.attEuler(3);
Setpoint.time = SimParams.timeInit;
Setpoint.posn(1) = IC.posn(1);
Trajectory = Setpoint;

IC.linVel =  rotMat*[VxImpact;0;0];

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
Sensor = initsensor(state, stateDeriv);

% Initialize history 
Hist = inithist(SimParams.timeInit, state, stateDeriv, Pose, Twist, Control, PropState, Contact, localFlag, Sensor);

% Initialize Continuous History
if SimParams.recordContTime == 1 
    ContHist = initconthist(SimParams.timeInit, state, stateDeriv, Pose, Twist, Control, ...
                            ProTrajectorypState, Contact, globalFlag, Sensor);
end

% Simulation Loop
for iSim = SimParams.timeInit:tStep:SimParams.timeFinal-tStep
 %1/200;
%     display(iSim)   
    
    % Impact Detection    
    [ImpactInfo, ImpactIdentification] = detectimpact(iSim, tStep, ImpactInfo, ImpactIdentification,...
                                                      Hist.sensors,Hist.poses,PREIMPACT_ATT_CALCSTEPFWD, stateDeriv,state);
    [FuzzyInfo] = fuzzylogicprocess(iSim, ImpactInfo, ImpactIdentification,...
                                    Sensor, Hist.poses(end), SimParams, Control, FuzzyInfo);
                                
    % Calculate accelref in world frame based on FuzzyInfo.output, estWallNormal
    if sum(FuzzyInfo.InputsCalculated) == 4 && Control.accelRefCalculated == 0;
            %Control.accelRef = calculaterefacceleration(FuzzyInfo.output, ImpactIdentification.wallNormalWorld);
            
            Control.accelRef = 4.8*ImpactIdentification.wallNormalWorld;
            Control.accelRefCalculated = 1;
    end
    
    % Control
    if Control.accelRefCalculated*SimParams.useRecovery == 1 %recovery control       
        if SimParams.useFaesslerRecovery == 1  
            
            Control = checkrecoverystage(Pose, Twist, Control, ImpactInfo);
            [Control] = computedesiredacceleration(Control, Twist);

            % Compute control outputs
            [Control] = controllerrecovery(tStep, Pose, Twist, Control);       
            Control.type = 'recovery';
            
        else %Setpoint recovery
            disp('Setpoint recovery');
            Control.pose.posn = IC.posn;
            Control = controllerposn(state,iSim,SimParams.timeInit,tStep,Trajectory(end).head,Control);
            Control.type = 'posn';
        end
    else % normal attitude control
        Control.recoveryStage = 0;
        Control.desEuler = IC.attEuler;
        Control.pose.posn(3) = IC.posn(3);
        Control = controlleratt(state,iSim,SimParams.timeInit,tStep,Control,[]);
        Control.type = 'att';
    end
    
    % Propagate Dynamics
    options = getOdeOptions();
    [tODE,stateODE] = ode45(@(tODE, stateODE) dynamicsystem(tODE,stateODE, ...
                                                            tStep,Control.rpm,ImpactParams,PropState.rpm, ...
                                                            Experiment.propCmds),[iSim iSim+tStep],state,options);
    
    % Reset contact flags for continuous time recording        
    globalFlag.coninitpropstatetact = localFlag.contact;
    
    % Record History
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
    
    %% Update Sensors
    Sensor = updatesensor(state, stateDeriv);

    % Discrete Time recording @ 200 Hz
    Hist = updatehist(Hist, t, state, stateDeriv, Pose, Twist, Control, PropState, Contact, localFlag, Sensor);

    % Navi has crashed:
    if state(9) <= 0
        display('Navi has hit the floor :(');
        ImpactInfo.isStable = 0;
        break;
    end  
    
    % Navi has drifted very far away from wall:
    if state(7) <= -10
        display('Navi has left the building');
        ImpactInfo.isStable = 1;
        break;
    end
    

end


Plot = hist2plot(Hist);
%%
close all
% animate(0,1,Hist,'XY',ImpactParams,timeImpact,'NA',50);
% plot(Plot.times,Plot.defls(:,4),'--')
% hold on
% plot(Plot.times,Plot.defls(:,4),'*')
% legend('bumper 1','bumper 4')
% grid on

%%
close all
% plot(Plot.times,Plot.eulerAngleRates(2,:))
% plot(Plot.times,Plot.defls)
hold on
plot(Plot.times,Plot.contactPtVelocityWorlds_bump1)
legend('x','y','z')
grid on