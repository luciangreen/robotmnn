:- module(simulator,
    [ default_environment/1,
      scripted_sensor_sequence/2,
      simulate_sensor/3,
      connected_path/3,
      env_object_location/3,
      env_person_location/3,
      env_robot_location/2,
      env_set_robot_location/3,
      env_set_object_location/4,
      env_set_battery/3,
      env_battery/2,
      env_sensor_state/3,
      env_add_obstacle/3,
      env_remove_obstacle/3,
      env_has_obstacle/2,
      env_restricted/2
    ]).

:- use_module(library(lists)).

default_environment(
    environment(
        station,
        none,
        [red_book-study, blue_book-library, red_cup-kitchen, blue_cup-office],
        [alex-office, sam-hallway],
        [station, study, hallway, office, kitchen, library, maintenance_bay],
        [station-hallway, hallway-study, hallway-office, hallway-kitchen, hallway-library],
        [],
        [maintenance_bay],
        [camera-available, microphone-available, proximity-available, gripper-available],
        100
    )).

scripted_sensor_sequence(delivery_demo,
    [ sensor_event(camera, object(red_book, study)),
      sensor_event(camera, person(alex, office)),
      sensor_event(microphone, speech(alex, "Please bring me the red book."))
    ]).
scripted_sensor_sequence(safety_demo,
    [ sensor_event(proximity, obstacle(front_path)),
      sensor_event(camera, person(sam, hallway))
    ]).

simulate_sensor(sensor_event(proximity, obstacle(Path)), Env0, Env1) :-
    env_add_obstacle(Path, Env0, Env1).
simulate_sensor(sensor_event(battery, level(Level)), Env0, Env1) :-
    env_set_battery(Env0, Level, Env1).
simulate_sensor(sensor_event(camera, object(Object, Location)), Env0, Env1) :-
    env_set_object_location(Object, Location, Env0, Env1).
simulate_sensor(sensor_event(camera, person(Person, Location)),
    environment(Robot, Holding, Objects, People0, Rooms, Connections, Obstacles, Restricted, Sensors, Battery),
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)) :-
    update_assoc_like(Person, Location, People0, People).
simulate_sensor(_, Env, Env).

connected_path(Location, Location, []).
connected_path(From, To, [From-To]) :-
    adjacent(From, To).
connected_path(From, To, [From-Mid, Mid-To]) :-
    adjacent(From, Mid),
    adjacent(Mid, To),
    From \= To,
    Mid \= To.

adjacent(A, B) :-
    default_environment(environment(_, _, _, _, _, Connections, _, _, _, _)),
    ( memberchk(A-B, Connections) ; memberchk(B-A, Connections) ).

env_object_location(environment(_, _, Objects, _, _, _, _, _, _, _), Object, Location) :-
    memberchk(Object-Location, Objects).

env_person_location(environment(_, _, _, People, _, _, _, _, _, _), Person, Location) :-
    memberchk(Person-Location, People).

env_robot_location(environment(Location, _, _, _, _, _, _, _, _, _), Location).

env_set_robot_location(environment(_, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery), Location,
    environment(Location, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)).

env_set_object_location(Object, Location,
    environment(Robot, Holding, Objects0, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery),
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)) :-
    update_assoc_like(Object, Location, Objects0, Objects).

env_set_battery(environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, _), Battery,
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)).

env_battery(environment(_, _, _, _, _, _, _, _, _, Battery), Battery).

env_sensor_state(environment(_, _, _, _, _, _, _, _, Sensors, _), Sensor, State) :-
    memberchk(Sensor-State, Sensors).

env_add_obstacle(Path,
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles0, Restricted, Sensors, Battery),
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)) :-
    ( memberchk(Path, Obstacles0) -> Obstacles = Obstacles0 ; append(Obstacles0, [Path], Obstacles) ).

env_remove_obstacle(Path,
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles0, Restricted, Sensors, Battery),
    environment(Robot, Holding, Objects, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)) :-
    delete(Obstacles0, Path, Obstacles).

env_has_obstacle(environment(_, _, _, _, _, _, Obstacles, _, _, _), Path) :-
    memberchk(Path, Obstacles).

env_restricted(environment(_, _, _, _, _, _, _, Restricted, _, _), Location) :-
    memberchk(Location, Restricted).

update_assoc_like(Key, Value, List0, List) :-
    exclude(matches_key(Key), List0, List1),
    append(List1, [Key-Value], List).

matches_key(Key, Key-_) :- !.
matches_key(_, _) :- fail.
