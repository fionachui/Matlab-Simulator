function Hist = inithist(timeInit, state, stateDeriv, Pose, Twist, Control, PropState, Contact, localFlag,...
                        Sensor, sensParams, EKF, AEKF, SPKF, ASPKF, COMP, HINF, SPKF_full,EKF_att,SRSPKF,...
                        SRSPKF_full, ASPKF_opt, AHINF,SPKF_norm, useExpData)
                
% Initialize history of the state and its derivative
if useExpData == 0
Hist.states = state;
Hist.stateDerivs = stateDeriv;
Hist.times = timeInit;

% Initialize history of twist, pose and control structs
Hist.poses = Pose;
Hist.twists = Twist;
Hist.controls = Control;

Hist.contacts = Contact;
Hist.propStates = PropState;
Hist.localFlag.contact.isContacts = localFlag.contact.isContact;
Hist.localFlag.contact.initialNormalVels = localFlag.contact.initialNormalVel;

Hist.crash = sensParams.crash;
end

Hist.sensors = Sensor;


% Hist.EKF = EKF;
% Hist.AEKF = AEKF;

Hist.SPKF = SPKF;
Hist.ASPKF = ASPKF;

Hist.COMP = COMP;

Hist.HINF = HINF;

% Hist.SPKF_full = SPKF_full;

Hist.EKF_att = EKF_att;
Hist.SRSPKF = SRSPKF;
% Hist.SRSPKF_full = SRSPKF_full;
Hist.ASPKF_opt = ASPKF_opt;
Hist.AHINF = AHINF;
Hist.SPKF_norm = SPKF_norm;



end
