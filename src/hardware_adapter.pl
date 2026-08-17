:- module(hardware_adapter,
    [ robot_move/2,
      robot_turn/2,
      robot_grasp/2,
      robot_release/2,
      robot_speak/2,
      robot_sensor_read/2
    ]).

robot_move(Location, adapter_command(move_to(Location), simulated)).
robot_turn(Angle, adapter_command(turn(Angle), simulated)).
robot_grasp(Object, adapter_command(grasp(Object), simulated)).
robot_release(Object, adapter_command(release(Object), simulated)).
robot_speak(Text, adapter_command(say(Text), simulated)).
robot_sensor_read(Sensor, adapter_command(read(Sensor), simulated)).
