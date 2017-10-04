close all
hold on
grid on
numPitch = 46;
numOffset = 71;
for iPitch = 1%:numPitch
    for iOffset = 1%:numOffset
        trial = 71*(iPitch-1)+iOffset;
        disp(trial);
        offset = cell2mat(Batch(trial,1));
        pitch = cell2mat(Batch(trial,2));
        times = cell2mat(Batch(trial,7));
        positions = cell2mat(Batch(trial,6));
        deflections = cell2mat(Batch(trial,7));
        recoveryStages = cell2mat(Batch(trial,8));
        states = cell2mat(Batch(trial,11));
        EulerAngles = cell2mat(Batch(trial,12));
        phi = EulerAngles(1,:);
        theta = EulerAngles(2,:);
        psi = EulerAngles(3,:);
    end
end
 
% plot(times(:),phi(:));
% plot(times(:),theta(:));
% plot(times(:),psi(:));
% legend('Roll(\phi)','Pitch(\theta)', 'Yaw(\psi)');
% title(strcat('Euler Angles (\phi, \theta, \psi) for Pitch = ',num2str(-pitch),'^o'));
% xlabel('Time(s)');
% ylabel('EulerAngles(rad)');


% floor=-ones(1,401);
% plot(times(:),states(9,:));
% plot(times(:),floor(:),'r-');
% legend('Height','Floor');
% title(strcat('Height variation for Pitch = ',num2str(-pitch),'^o'));
% xlabel('Time(s)');
% ylabel('Height(m)');

