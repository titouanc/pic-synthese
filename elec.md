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

De nouveau ici si on note m, la valeur de prescale alors la fréquence de référence est `F/m`, on a alors la période `p = m\*n/F [s] et f = F/(n\*m)` [Hz] .

## Mode 32 bits

Il est possible d'utiliser les timers 2 et 3 (16 bits) ou 4 et 5 en combinaison pour obtenir un timer 32 bits

* Mettre la paire 2/3 en mode 32 bits : `T2CONbits.T32 = 1`
* Mettre les 16 bits de poids faible dans PR2
* Mettre les 16 bits de poids fort dans PR3
* Configurer eventuellement le prescaling sur le timer 2
* Configurer eventuellement l'interruption sur le timer 3
* Lancer le timer 2 : `T2CONbits.TON = 1`

# ADC

Le PIC est équippé de 32 entrées analogiques, dont 3 utilisables sur la carte
d'extension (`AN0`, `AN1`, `AN3`). Les ADC mesurent une tension de 3.3V sur 10 bits.
La conversion n'est pas instantanée (plusieurs microsecondes).
Dans la suite, remplacer x par le numéro de l'ADC (1 ou 2)

* Mettre l'horloge pour contrôler le temps de conversion. La numérisation nécessite
12 périodes (12 T AD ) en mode 10 bits et 14 périodes (14 T AD ) en mode 12 bits.
Lorsqu’elle est basée sur l’horloge du cycle machine (F CY ), l’horloge de l’ADC est configurable à l’aide
des 8 bits ADCS de ADxCON3. La période T AD est alors donnée par :
Pour qu’une numérisation se déroule correctement, cette période doit être supérieure à 75ns.
* On peut mesurer la valeur sur 12 bits en mettant le bit `ADxCON1bits.AD12B` à 1
* Choisir l'entrée sur laquelle écouter : `ADxCHS0.CHS0A = y` où `y` est l'entrée
* Mettre l'entrée choisie en mode analogique : `ADxPCFGLbits.PCFGy = 0`
* Activer l'ADC : `ADxCON1bits.ADON = 1`
* Lancement de la conversion: `ADxCON1bits.SAMP = 0`
* Quand la conversion est terminée, le bit `ADxCON1bits.DONE` est mis à 1, et doit être remis à 0 manuellement. 
* Le résultat de la conversion est lisible dans le registre `ADCxBUF0` (16 bits).

## Relier l'ADC au Timer 3

Il est possible de configurer l'ADC1 pour lancer une conversion sur débordement
du timer 3 (idem pour l'ADC2 avec le timer 5), auquel cas il n'est pas nécessaire de tester et réinitialiser le bit 
`IFS0bits.TxIF` par contre il faut remettre le bit `IFS0.ADxIF` à 0.
La routine d'interruption est `_ADC1Interrupt`

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

Puis remettre le flag à 0
`IFS0bits.TxIF = 0`
`IFS0bits.ADCyF = 0`

# PWM

Le dsPIC33F possède 8 périphériques de comparaison de sortie (Output Compare),
connectés sur les ports `RD0` à `RD7`, renommés `OC1` à `OC8` si utilisés comme
tel. Le principe du PWM peut être vu comme un timer à deux registres de comparaison.

Pour ce faire, on configure un timer usuellement, et on définit une période
active dans un deuxième registre, dans les mêmes unités que la période du timer.

__Seul les timers 2 et 3 peuvent être utilisés pour le PWM__

## Configuration

* Définition de la période du timer: `PR2 = periode` ou `PR3 = periode`
* Définition de la période "active": `OCxRS = periode_active`
* Mettre OCx en PWM : `OCxCONbits.OCM = 0b110
* Définition du timer à utiliser : `OCxCONbits.OCTSEL = 0` (0 pour timer 2, 1 pour timer 3)

__Ne pas oublier de mettre la patte RD(x-1) en sortie__

__Ne pas oublier de lancer le timer__


Exemple:

    PR2 = 40000   // Timer 2 à 1kHz
    OC1RS = 10000 // Période active de 1/4 de la période du timer 
                  // (25% de puissance moyenne)

# Communication série (UART)

__UART: Universal Asynchronous Receiver Transmitter__. Le dsPIC33f en comporte 2
qui utilisent le protocole série standard RS-232.

Il faut configurer plusieurs paramètres:

* Le baud-rate (souvent 9600, 62500 ou 115200 bauds)
* La taille d'un symbole (nombre de bits, généralement 8)
* Le bit de parité: aucun, pair ou impair (contrôle d'erreur)
* Le stop bit: temps de silence après l'émission d'un symbole (généralement 1 bit)

On désigne parfois le format en plus court. Exemple: 8N1 = symboles de 8 bits,
pas de bit de parité, 1 stop bit.


## Configuration
Les UARTs 1 et 2 sont dénommés `x` ci après

* Ecrire le baud rate dans UxBRG, selon la formule `( FCy/(16*bauds) ) - 1`
* Si besoin d'un plus grand baud rate, on peut mettre le bit UxMODEbits.BRGH à 1, la formule devient `( FCy/(4*bauds) ) - 1`
* Sélection du mode de parité et de la taille des symboles: `UxMODEbits.PDSEL = 0b00`
* Sélection du nombre de bits de stop: `UxMODEbits.STSEL = 0` (`0`=1 stop bit, `1`=2stop bits)
* Sélection du mode de réception: `UxSTAbits.URXISEL = 0b00`
* Activation de l'UART: `UxMODEbits.UARTEN = 1`
* Activation de l'émetteur: `UxSTAbits.UTXEN = 1` (uniquement si on souhaite émettre)
* Activation de l'interruption: `IEC0bits.U1RXIE` pour l'UART 1, `IEC1bits.U2RXIE` pour l'UART 2

### Modes de parité

Signification des valeurs pour le flag `UxMODEbits.PDSEL`

* `0b00` 8 bits de données, pas de bit de parité
* `0b01` 8 bits de données, parité paire
* `0b10` 8 bits de données, parité impaire
* `0b11` 9 bits de données, pas de bit de parité

### Modes de réception

Signification des valeurs pour le flag `UxSTAbits.URXISEL`

* `0b00` Déclenchement de l'interruption après réception d'un byte
* `0b10` Déclenchement de l'interruption quand le buffer est rempli aux 3/4
* `0b11` Déclenchement de l'interruption quand le buffer de réception est rempli



## Émission

* Avant d'émettre, il faut vérifier qu'il ya de la place dans le buffer d'émission: `while (UxSTAbits.UTXBF == 1)`
* Placer le caractère dans le buffer: `UxTXREG = caractère`
* Attendre que le caractère soit transmis: `while (UxSTAbits.TRMT == 0)`

## Réception

Si la réception est configurée sur interruption, il faut définir une Interrupt Service Routine

    void _ISR _UxRXInteerupt(void){
        /* Tant qu'il ya des données disponibles dans le buffer d'entrée... */
        while (UxSTAbits.URXDA){
            char received = UxRXREG;
        }
    }

Il ne faut pas shifter le buffer d'entrée manuellement.

