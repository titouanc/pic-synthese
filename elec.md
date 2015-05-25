# Entrées / Sorties numériques

Plusieurs séries d'I/O (PORTA à PORTG), `x` ci-après. Certaines font
8 bits de large, d'autres 16.

**Attention, certaines pattes sont partagées avec l'ADC**

## Registres de direction des pattes I/O
* 1 = entrée, 0 = sortie
* `TRISx = 0x0001` pour configurer la patte 0 en entrée, tout le reste en sortie
* `TRISxbits.TRISx0 = 1` pour configurer l'entrée individuellement

## Registres de sortie des pattes I/O
* `LATx = 0x0001` pour écrire tous les bits en une fois
* `LATxbits.LATx0 = 1` pour écrire un bit individuellement

## Registres d'entrée des pattes I/O
* `int val = PORTx` pour lire toutes les entrées en une fois
* `int val = PORTx.Rx0` pour lire l'entrée individuellement 

# Timers

## Configuration

* Registres de période des timers: `PR1` à `PR9`, en nombre de cycles du processeur
* `PRx = n`; va multiplier par n la durée d'une période du timer x et du coup, diviser par n le nombre de périodes par seconde. Pour faire simple, en prennant F=40.10^6 (la fréquence horloge voir clock_init() ) p = n/F [s] et f = F/n [Hz]  \(!Attention! n<2^16 )

* Démarrer le timer: `T1CONbits.TON = 1` à `T9CONbits.TON = 1`
* Vérifier si la valeur du timer est atteinte: `IFS0bits.T1IF` à `IFS0bits.T9IF`
* __Il faut remettre ce bit à 0 manuellement !__

## Prescaling

Les registres de timer font 16 bits (max 65535 = 1638s). On peut utiliser
un prescaler (diviseur d'horloge), de facteur 8, 64 ou 256.

* `T1CONbits.TCKPS = 0b00` Pas de prescaling (1)
* `T1CONbits.TCKPS = 0b01` Prescaling de 8
* `T1CONbits.TCKPS = 0b10` Prescaling de 64
* `T1CONbits.TCKPS = 0b11` Prescaling de 256

# ADC

Le PIC est équippé de 32 entrées analogiques, dont 3 utilisables sur la carte
d'extension (`AN0`, `AN1`, `AN3`). Les ADC mesurent une tension de 3.3V sur 10 bits.
La conversion n'est pas instantanée (plusieurs microsecondes). 

* Lancement de la conversion: `AD1CON1bits.SAMP = 0`
* Quand la conversion est terminée, le bit `IFS0.AD1IF` est mis à 1, et doit être
remis à 0 manuellement. 
* Le résultat de la conversion est lisible dans le registre `ADC1BUF0` (16 bits).

## Relier l'ADC au Timer 3

Il est possible de configurer l'ADC1 pour lancer une conversion sur débordement
de timer, auquel cas il n'est pas nécessaire de tester et réinitialiser le bit
`IFS0bits.T3IF`.

* "Connecter" l'ADC 1 au timer 3: `AD1CON1bits.SSRC = 2`
* "Connecter" l'ADC 2 au timer 5: `AD2CON1bits.SSRC = 2`

# Interruptions

Il est possible d'appeler une fonction "callback" lors du déclenchement d'un
évènement comme le débordement d'un timer, la fin d'une conversion ADC ou la
réception d'un caractère sur le port série.

* Activer l'interruption pour un timer: `IEC0bits.TxIE = 1` (où `x` est le numéro du timer de 1 à 3)
* Activer l'interruption pour un ADC: `IEC0bits.ADyIE = 1` (où `y` est le numéro de l'ADC)

Il faut ensuite écrire la routine d'interruption correspondante:

    /* Routine d'interruption de débordement du Timer 1 */
    void _ISR _T1Interrupt (void){}

    /* Routine d'interruption de fin de conversion de l'ADC1 */
    void _ISR _ADC1Interrupt (void){}

# PWM

Le dsPIC33F possède 8 périphériques de comparaison de sortie (Output Compare),
connectés sur les ports `RD0` à `RD7`, renommés `OC1` à `OC8` si utilisés comme
tel. Le principe du PWM peut être vu comme un timer à deux registres de comparaison.

Pour ce faire, on configure un timer usuellement, et on définit une période
active dans un deuxième registre, dans les mêmes unités que la période du timer.

## Configuration

* Définition de la période du timer: `PR2 = periode` ou `PR3 = periode`
* Définition de la période "active": `OCxRS = periode_active`

Exemple:

    PR2 = 40000   // Timer 2 à 1kHz
    OC1RS = 10000 // Période active de 1/4 de la période du timer 
                  // (25% de puissance moyenne)

# Communication série (UART)


