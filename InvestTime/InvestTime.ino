// Pin Definitions
const int bpodInvestSignal  = 2;  // Bpod BNC 1 (Start/Stop Stopwatch)
const int bpodOutcomeSignal = 3;  // Bpod BNC 2 (The Trigger)
const int bpodSideSignal    = 4;  // Bpod Flex 1 (LOW = Left, HIGH = Right)
const int bpodValenceSignal = 7;  // Bpod Flex 2 (LOW = Error, HIGH = Correct)
const int bpodActionPulse   = 10; // Return Pulse to Bpod BNC 1 In

//const float K = 0.5; 
// --- Hardware Calibration Settings ---
// Left Valve (Valve 1)
const float L_coeff_A = 0.015;
const float L_coeff_B = 1.15;
const float L_coeff_C = 2.4;

// Right Valve (Valve 4)
const float R_coeff_A = 0.012;
const float R_coeff_B = 1.18;
const float R_coeff_C = 2.1;

unsigned long startTime = 0;
unsigned long investTime = 0;
bool isInvesting = false;
bool outcomeDelivered = false;

void setup() {
  Serial.begin(9600);
  pinMode(bpodInvestSignal, INPUT);
  pinMode(bpodOutcomeSignal, INPUT);
  pinMode(bpodSideSignal, INPUT); 
  pinMode(bpodValenceSignal, INPUT);
  pinMode(bpodActionPulse, OUTPUT);

// --- NEW DIAGNOSTIC TEST ---
  Serial.println("Testing BNC connection for 5 seconds...");
  digitalWrite(bpodActionPulse, HIGH);
  delay(5000);
  digitalWrite(bpodActionPulse, LOW);
  Serial.println("Test complete. Rig Ready.");
  //

  digitalWrite(bpodActionPulse, LOW);
  Serial.println("Arduino Ready. Waiting for Bpod...");
}

void loop() {
  int investState = digitalRead(bpodInvestSignal);
  int outcomeState = digitalRead(bpodOutcomeSignal);

  // 1. Detect entry
  if (investState == HIGH && !isInvesting) {
    startTime = millis();
    isInvesting = true;
    outcomeDelivered = false; 
    Serial.println("Bpod says: Animal is INVESTING...");
  }

  // 2. Detect exit
  if (investState == LOW && isInvesting) {
    investTime = millis() - startTime;
    isInvesting = false;
    Serial.print("Investment ended. Time (ms): ");
    Serial.println(investTime);
  }

  // 3. Detect Outcome Trigger
  if (outcomeState == HIGH && !outcomeDelivered && investTime > 0) {
    delay(5);
    unsigned long actionDuration = 0;
    // Read the Flex ports the exact millisecond the Trigger hits
    int sideState = digitalRead(bpodSideSignal);
    int valenceState = digitalRead(bpodValenceSignal);
    // --- VALENCE ROUTING ---bpod
    
    if (valenceState == HIGH) {
        // CORRECT CHOICE: Run f1 (Reward Volume Math)
        
        // Placeholder for f1: Convert investTime (ms) to targetVolume (uL)
        float targetVolume = investTime*0.3; 
        
        // Apply Side-Specific Calibration Curve
        if (sideState == HIGH) {
            // Right Valve (Flex 1 is HIGH)
            actionDuration = (R_coeff_A * targetVolume * targetVolume) + (R_coeff_B * targetVolume) + R_coeff_C;
            Serial.print("RIGHT Reward. Pulse: ");
        } else {
            // Left Valve (Flex 1 is LOW)
            actionDuration = (L_coeff_A * targetVolume * targetVolume) + (L_coeff_B * targetVolume) + L_coeff_C;
            Serial.print("LEFT Reward. Pulse: ");
        }
        Serial.println(actionDuration);
        
    } else {
        // ERROR CHOICE: Run f2 (Punishment Duration Math)
        
        // Placeholder for f2: Convert investTime (ms) to white noise duration (ms)
        actionDuration = investTime * 0.5; // Example scaling
        
        Serial.print("PUNISHMENT. Pulse: ");
        Serial.println(actionDuration);
    }

    actionDuration = constrain(actionDuration, 10, 6000); 

    //Serial.print("Bpod says: Animal is at OUTCOME. Firing pulse for (ms): ");
    //Serial.println(actionDuration);

    digitalWrite(bpodActionPulse, HIGH);
    Serial.print(" Tell Bpod what to do ");
    delay(actionDuration);
    digitalWrite(bpodActionPulse, LOW);

    outcomeDelivered = true;
    investTime = 0; 
  }
}