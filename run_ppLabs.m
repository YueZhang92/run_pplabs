function [ success ] = run_ppLabs( listener)
%running demo


%----
% 1. Macros
%----
%add ZMQ to path
addpath(genpath('C:\Users\Admin\Documents\MATLAB\'));
dummymode=0;
beep off;


%setting time
StartTime=fix(clock);
FileStartTime=sprintf('%02d-%02d', StartTime(4), StartTime(5));
StartTimeString=sprintf('%02d:%02d:%02d', StartTime(4), StartTime(5), StartTime(6));
StartDate= date;



%---
%3. setting up pupilLabs
if dummymode == 0 %for real run
% Pupil Remote address
endpoint =  'tcp://127.0.0.1:50020';
% Setup zmq context and remote helper
ctx = zmq.core.ctx_new();
socket = zmq.core.socket(ctx, 'ZMQ_REQ');
% set timeout to 1000ms in order to not get stuck in a blocking
% mex-call if server is not reachable, see
% http://api.zeromq.org/4-0:zmq-setsockopt#toc19
zmq.core.setsockopt(socket, 'ZMQ_RCVTIMEO', 1000);
fprintf('Connecting to %s\n', endpoint);
zmq.core.connect(socket, endpoint);
tic; % Measure round trip delay
zmq.core.send(socket, uint8('t'));
result = zmq.core.recv(socket);
fprintf('%s\n', char(result));
fprintf('Round trip command delay: %s\n', toc);
%start annotation plugin
send_notification(socket, containers.Map({'subject','name'}, {'start_plugin','Annotation_Capture'}))
zmq.core.recv(socket);
%start pupil remote plugin
send_notification(socket, containers.Map({'subject','name'}, {'start_plugin','Pupil_Remote'}))
zmq.core.recv(socket);
% set current Pupil time to 0.0
zmq.core.send(socket, uint8('T 0.0'));
result = zmq.core.recv(socket);
fprintf('%s\n', char(result));
% Set pupil detection mode to 3D
topic = uint8(char('notify.set_detection_mapping_mode'));
payload = containers.Map({'subject','mode'},{'set_detection_mapping_mode','2d'});
msgpackpayload = dumpmsgpack(payload);
zmq.core.send(socket, topic, 'ZMQ_SNDMORE');
zmq.core.send(socket, msgpackpayload);
char(zmq.core.recv(socket)) % client recv
pause(0.5)

% Start the pupil0 process (right-eye)
topic = uint8(char('notify.eye_process.should_start.0'));
payload = containers.Map({'subject','eye_id'},{'eye_process.should_start.0',uint8(0)});
msgpackpayload = dumpmsgpack(payload);
zmq.core.send(socket, topic, 'ZMQ_SNDMORE');
zmq.core.send(socket, msgpackpayload);
char(zmq.core.recv(socket)) % client recv
pause(0.5)
%
% Start the pupil1 process (left-eye)
topic = uint8(char('notify.eye_process.should_start.1'));
payload = containers.Map({'subject','eye_id'},{'eye_process.should_start.1',uint8(1)});
msgpackpayload = dumpmsgpack(payload);
zmq.core.send(socket, topic, 'ZMQ_SNDMORE');
zmq.core.send(socket, msgpackpayload);
char(zmq.core.recv(socket)) % client recv
pause(0.5)
%--
%calibration - done externally with
% test notification, note that you need to listen on the IPC to receive notifications!
% send_notification(socket, containers.Map({'subject','name'}, {'calibration.should_start',''}))
% result = zmq.core.recv(socket);
% fprintf('Notification received: %s\n', char(result));
% WaitSecs(40);
% send_notification(socket, containers.Map({'subject'}, {'calibration.should_stop'}))
% result = zmq.core.recv(socket);
% fprintf('Notification received: %s\n', char(result));%--
% uiwait(msgbox('Calibration done.'));



%----
% % 5. start recording
% %-----
WaitSecs(1);
%name the folder by listener with date
sessionID = [ 'try_' StartDate '_' FileStartTime ];
send_notification(socket, containers.Map({'subject','session_name'}, {'recording.should_start',sessionID}))
result = zmq.core.recv(socket);
fprintf('Recording should start: %s\n', char(result));
WaitSecs(2);
%getting timestamp for starting
zmq.core.send(socket, uint8('t'));
event_tmsp= char(zmq.core.recv(socket));
send_notification(socket, containers.Map({'subject','label','timestamp','duration','source','record'}, {'annotation','start',str2double(event_tmsp),1.0,'pupilLabs',1.0}))
result = zmq.core.recv(socket);
fprintf(char(result));
%play the imaginery sentence
zmq.core.send(socket,uint8('R'));
result = zmq.core.recv(socket);
fprintf(char(result));

%marking during sentence start of baseline (1s)
fprintf('baseline = %f\n',clock); %for debugging
zmq.core.send(socket, uint8('t'));
event_tmsp= char(zmq.core.recv(socket));
send_annotation(socket, containers.Map({'topic','label','timestamp','duration','record'}, {'annotation','baseline',str2double(event_tmsp),1.0,1.0}))
           result = zmq.core.recv(socket);
          fprintf(char(result));
          WaitSecs(1);
         
          %start of playing the sentence 
%           fprintf(' listen = %f\n',clock);
%           clock) % for debugging
          zmq.core.send(socket, uint8('t'));
           event_tmsp= char(zmq.core.recv(socket));
          send_annotation(socket, containers.Map({'topic','label','timestamp','duration','record'}, {'annotation','listen',str2double(event_tmsp),1.0,1.0}))
           result = zmq.core.recv(socket);
          fprintf(char(result));
          WaitSecs(4);
          
          %start of wait peak time (2s) 
          %fprintf('waitpeak = %f\n', clock);
          %%for debugging
          zmq.core.send(socket, uint8('t'));
          event_tmsp= char(zmq.core.recv(socket));
          send_annotation(socket, containers.Map({'topic','label','timestamp','duration','record'}, {'annotation','waitpeak',str2double(event_tmsp),1.0,1.0}))
           result = zmq.core.recv(socket);
           fprintf(char(result));
          WaitSecs(2);
          WaitSecs(0.1); %noise taper off
          
          
         
%stop this recording section 
zmq.core.send(socket,uint8('r'));
result = char(zmq.core.recv(socket));
disp('Stop eye tracker...')
%...and do another recording section within the same folder
zmq.core.send(socket,uint8('R'));
result = zmq.core.recv(socket);
fprintf('Recording should start: %s\n', char(result));
WaitSecs(2);



    
uiwait(msgbox('end of the experiment.'));
    
%stop the recording
send_notification(socket, containers.Map({'subject','session_name'}, {'recording.should_stop',sessionID}))
result = zmq.core.recv(socket);
fprintf('Recording stopped: %s\n', char(result));

%disconnect the eyetracker
zmq.core.close(socket);



end


