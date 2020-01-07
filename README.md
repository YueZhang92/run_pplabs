# run_pplabs
driving a pupillometry hearing experiment, and processing the pupil traces using pupilLabs from Matlab


# Requirements
- download pupilLabs interface from: https://github.com/pupil-labs/pupil/releases
- get zmq from: https://zeromq.org/download/
- get pupilLabs helping funtions from: https://github.com/pupil-labs/pupil-helpers/tree/master/matlab
- make sure everything is included in the MATLAB path
- start Pupil Capture

# Running
`run_ppLabs('00')`

# Analysing
- drag the output recordings to Pupil Player
- make sure annotation player is on and click export
- use annotations.csv and pupil_positions.csv as inputs to the readpupil.m function
`readpupil('pupil_positions.csv', 'annotations.csv', 120)`
- readpupil.m outputs two folders of figures (pre- and post-processing pupil trace cleaning), a processed (deblinked, smoothed and downsampled) pupil data file, and a vector of trials with blinks/missing data taking over 20% of the recordings.


