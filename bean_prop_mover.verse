<# 
    A VERSE FILE FOR MOVING PROPS USING THE ANIMATION CONTROLLER
    CREATED BY COURI (@fncouri on X)
#>


using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation/InterpolationTypes }

movement_type := enum:
    Spin #360 around an axis
    PingPong #Move back and forth between two points
    Pendulum #Rotate back and forth around a point

movement_axis := enum:
    X
    Y
    Z
    
    

animated_bean_prop := class<concrete>():

    @editable
    CycleDuration : float = 1.0 #Duration of 1 full cycle in seconds

    @editable
    BeanProp : creative_prop = creative_prop{} #creative prop to animate

    @editable
    MovdmentType : movement_type = movement_type.Spin #Type of movement to perform

    @editable
    SpinClockwiseDirection : logic = true #Direction of spin (only used for spin movement)

    @editable
    MovementAxis : movement_axis = movement_axis.X #Axis to move/rotate along 

    @editable
    MovementAmount : float = 0.0 #Amount to move/rotate


    PingPongMovement():[]keyframe_delta=
        InitialPosition := BeanProp.GetTransform()
        
        var StartPosition : vector3 = InitialPosition.Translation #not the actual start position, if the movement is along the X-axis, this will be the far left position the prop will reach during its movement
        var EndPosition  : vector3 = InitialPosition.Translation

        #Determines the start and end positions based on the selected axis
        if(MovementAxis = movement_axis.X):
            set StartPosition = InitialPosition.Translation - vector3{X:= MovementAmount, Y:= 0.0, Z:= 0.0}
            set EndPosition = InitialPosition.Translation + vector3{X:= MovementAmount,Y:= 0.0, Z:= 0.0}
            Print("Moving along X axis")

        if(MovementAxis = movement_axis.Y):
            set StartPosition = InitialPosition.Translation - vector3{X:= 0.0, Y:= MovementAmount, Z:= 0.0}
            set EndPosition = InitialPosition.Translation + vector3{X:= 0.0,Y:= MovementAmount, Z:= 0.0}
            Print("Moving along Y axis")
        
        if(MovementAxis = movement_axis.Z):
            set StartPosition = InitialPosition.Translation - vector3{X:= 0.0, Y:= 0.0, Z:= MovementAmount}
            set EndPosition = InitialPosition.Translation + vector3{X:= 0.0,Y:= 0.0, Z:= MovementAmount}
            Print("Moving along Z axis")

            
        Startframe := keyframe_delta:
            DeltaLocation := InitialPosition.Translation - StartPosition
            DeltaRotation := rotation{}
            Time := CycleDuration * 0.5
        Endframe := keyframe_delta:
            DeltaLocation := InitialPosition.Translation - EndPosition
            DeltaRotation := rotation{}
            Time := CycleDuration * 0.5
        Keys := array{Startframe, Endframe}
        return Keys


    #Creates the keyframes for a 360 spin around the selected axis 
    #Modified version of a code originally provided by https://x.com/thomasjanky
    SpinMovement():[]keyframe_delta=
        HalfPI := if(SpinClockwiseDirection?) then (1.57079632679) else (-1.57079632679) #Determines the direction of the spin
        var FinalRotation : rotation = rotation{}
        if(MovementAxis = movement_axis.X):
            set FinalRotation = rotation{}.ApplyRoll(HalfPI)
        if(MovementAxis = movement_axis.Y):
            set FinalRotation = rotation{}.ApplyPitch(HalfPI)
        if(MovementAxis = movement_axis.Z):
            set FinalRotation = rotation{}.ApplyYaw(HalfPI)
            
        Keyframe := keyframe_delta:
            DeltaLocation := vector3{}
            DeltaRotation := FinalRotation
            Time := CycleDuration * 0.25

        Keys := array{Keyframe, Keyframe, Keyframe, Keyframe}
        return Keys


    PendulumMovement():[]keyframe_delta=
        InitialRotation := BeanProp.GetTransform().Rotation

        var StartRotation : rotation = rotation{}
        var FinalRotation : rotation = rotation{}

        #Determines the type of rotation based on the selected axis
        if(MovementAxis = movement_axis.X):
            set StartRotation = InitialRotation.ApplyRoll(DegreesToRadians(MovementAmount))
            set FinalRotation = InitialRotation.ApplyRoll(DegreesToRadians(MovementAmount * -1))

        if(MovementAxis = movement_axis.Y):
            set StartRotation = InitialRotation.ApplyPitch(DegreesToRadians(MovementAmount))
            set FinalRotation = InitialRotation.ApplyPitch(DegreesToRadians(MovementAmount * -1))
        if(MovementAxis = movement_axis.Z):
            set StartRotation = InitialRotation.ApplyYaw(DegreesToRadians(MovementAmount))
            set FinalRotation = InitialRotation.ApplyYaw(DegreesToRadians(MovementAmount * -1))

        #Keyframes for the pendulum movement:
        StartFrame := keyframe_delta:
            DeltaLocation := vector3{}
            DeltaRotation :=  StartRotation
            Time := CycleDuration * 0.25
            Interpolation := EaseOut

        StartMidFrame := keyframe_delta:
            DeltaLocation := vector3{}
            DeltaRotation := StartRotation
            Time := CycleDuration * 0.25
            Interpolation := EaseIn

        EndMidFrame := keyframe_delta:
            DeltaLocation := vector3{}
            DeltaRotation := FinalRotation
            Time := CycleDuration * 0.25
            Interpolation := Linear

        EndFrame := keyframe_delta:
            DeltaLocation := vector3{}
            DeltaRotation := FinalRotation
            Time := CycleDuration * 0.25
            Interpolation := Linear

        Keys := array{StartFrame ,EndMidFrame,EndFrame, StartMidFrame}
        return Keys
        
        
        
    

    #Returns the keyframes for the selected movement type
    GetMovementKeys():[]keyframe_delta=
        if(MovdmentType = movement_type.Spin):
            return SpinMovement()
        if(MovdmentType = movement_type.PingPong):
            return PingPongMovement()
        if(MovdmentType = movement_type.Pendulum):
            return PendulumMovement()
        return array{}

    
bean_prop_mover := class(creative_device):

    @editable
    AnimatedBeans : []animated_bean_prop = array{} #Array of props to animate

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        for(AnimatedBean : AnimatedBeans):
            PlayAnim(AnimatedBean) #Play the animation for each prop on game start
 

    #Plays the animation for the selected prop
    PlayAnim(AnimatedBean : animated_bean_prop):void=
            if(Control := AnimatedBean.BeanProp.GetAnimationController[]):
                Keys :=AnimatedBean.GetMovementKeys() #Get the keyframes for the selected movement type
                Control.SetAnimation(Keys, ?Mode := animation_mode.Loop) #Set the animation
                Control.Play() #Play the animation
    
 
        
