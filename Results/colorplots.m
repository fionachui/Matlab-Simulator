%% Controller Improvement Plotter
% % close all
% figure();
% hold on
% grid on
% numPitch = 46;
% numOffset = 101;
% trial=0;
% improvements=0;
% failures=0;
% for iPitch = 1%:numPitch
%     heightLoss_with=[];
%     heightLoss_without=[];
% 
%     for iOffset = 1:numOffset
%        trial = trial+1;
%        disp(trial);
%        success_with = cell2mat(Batch(trial,3));
%        success_without = cell2mat(Batch2(trial,3));
%        positions_with = cell2mat(Batch(trial,8));  
%        positions_without = cell2mat(Batch2(trial,8)); 
%        heightLoss_with=[heightLoss_with, positions_with(3,1)-min(positions_with(3,:))];
%        heightLoss_without=[heightLoss_without, positions_without(3,1)-min(positions_without(3,:))];
%        
%        success_with = success_with*((heightLoss_with(end)<=2));
%        success_without = success_without*((heightLoss_without(end)<=2));
%        
%        if (success_with == 1)&&(success_without == 0)
%             improvements=improvements+1;
%             failures=failures+1;
%             h1=scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','g','MarkerEdgeColor','g');
%        elseif (success_with == 1)&&(success_without == 1)
%             h2=scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','y','MarkerEdgeColor','y');
%        else 
%            failures=failures+1;
%             h3=scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','r','MarkerEdgeColor','r');
%        end
%         
%         
%    end
% end
% 
% legend([h1 h2 h3],'Recovery Improvement due to Contoller','Recovery In Both Cases','Failure in Both Cases');
% title(strcat('Improvement Comparison With and Without Controller(Reflection Direction)  Improvement Cases: ',num2str(improvements),'/',num2str(failures)));
% xlabel('Pitch (degrees)');
% ylabel('Offset (normalized)');

%% Controller Blue Red plotter
% close all
figure();
hold on
grid on
numPitch = 46;
numOffset = 101;
heightLoss=[];
trial=0;
failures = 0;
for iPitch = 1%:numPitch
    for iOffset = 1:numOffset
        trial = trial+1;
        disp(trial);
        offset = cell2mat(Batch(trial,1));
        pitch = cell2mat(Batch(trial,2));
        success = cell2mat(Batch(trial,3));
        positions = cell2mat(Batch(trial,8));  
        heightLoss =[heightLoss, positions(3,1)-min(positions(3,:))];
        if (success==1)&&(heightLoss(end)<=2)
             h1=scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','b','MarkerEdgeColor','b');
        else
            failures = failures+1;
            h2=scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','r','MarkerEdgeColor','r');
        end        
   end
end

legend([h1 h2],'Successful Recovery','Failed Recovery');
title(strcat('With Recovery Controller (Normal Direction)','     Failure = ', num2str(failures),'/',num2str(trial)));
xlabel('Pitch (degrees)');
ylabel('Offset (normalized)');

%% Height variation colorplot
% close all
% hold on
% grid on
% numPitch = 46;
% numOffset = 71;
% height = [];
% heightset = [];
% trial=0;
% for iPitch = 1:numPitch
%     for iOffset = 1:numOffset
%         trial = trial+1;
%         disp(trial);
%         offset = cell2mat(Batch(trial,1));
%         pitch = cell2mat(Batch(trial,2));
%         success = cell2mat(Batch(trial,3));
%         normal = cell2mat(Batch(trial,4));
%         times = cell2mat(Batch(trial,5));
%         positions = cell2mat(Batch(trial,6));
%         deflections = cell2mat(Batch(trial,7));
%         recoveryStages = cell2mat(Batch(trial,8));
%         states = cell2mat(Batch(trial,9));
%         normalForces = cell2mat(Batch(trial,10));
%         timeImpact = cell2mat(Batch(trial,11));
% 
%         height = (positions(3,1)-positions(3,end));
%         heighset=[heightset height];
%         if height <= 6
%             color = [0, 1-(height+1)/7,  (height+1)/7];
%             
%                 h1 = scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor',color,'MarkerEdgeColor',color);
%             
%         elseif height >6 
%                 h2 = scatter(iPitch-1,-1+2*((iOffset-1)/(numOffset-1)),'MarkerFaceColor','r','MarkerEdgeColor','r');
% 
%          end
%         end
% end
% % histogram(height,78)
% title('With Recovery Height variation');
% legend([h2],'(height loss more than 6 meters)');
% xlabel('Pitch (degrees)');
% ylabel('Offset (normalized)');
% map=[0,1,0
%     0,.8,.2
%     0,.6,.4
%     0,.4,.6
%     0,.2,.8
%     0,0,1];
% colormap(map);
% 
