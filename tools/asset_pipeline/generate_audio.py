import math, os, random, struct, wave
OUT=os.path.abspath("GodotProject/assets/production/audio")
os.makedirs(OUT,exist_ok=True)
SR=22050  # Rendered master and effects use 22.05 kHz stereo PCM for compact mobile playback.
random.seed(918)
def env(t,d,a=0.02,r=0.3):
    return min(1,t/max(a,1e-4))*max(0,min(1,(d-t)/max(r,1e-4)))
def write_wav(name, samples):
    path=os.path.join(OUT,name)
    with wave.open(path,"wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        b=bytearray()
        for l,r in samples:
            b.extend(struct.pack("<hh",int(max(-1,min(1,l))*32767),int(max(-1,min(1,r))*32767)))
        w.writeframes(b)
def music():
    # Original generated fantasy-orchestra cue: layered string-like ensemble, brass-like
    # harmonic swells, harp ostinato, bell melody, low percussion, and a light room tail.
    dur=36.0; total=int(SR*dur); dry=[]
    chords=[(110.0,164.81,220.0),(98.0,146.83,196.0),(130.81,164.81,196.0),(87.31,130.81,174.61),
            (110.0,164.81,220.0),(130.81,196.0,261.63),(98.0,146.83,196.0),(82.41,123.47,164.81)]
    melody=[440,392,329.63,293.66,329.63,392,440,523.25,493.88,440,392,329.63,293.66,329.63,392,440]
    for i in range(total):
        t=i/SR; bar=int(t/4.5)%len(chords); local=t%4.5
        l=r=0.0
        # Ensemble strings: slightly detuned voices with attack/release and slow vibrato.
        for j,f in enumerate(chords[bar]):
            phase=2*math.pi*f*t
            vib=0.0018*math.sin(2*math.pi*(4.2+0.15*j)*t)
            voice=0.0
            for detune,weight in [(-0.0022,0.34),(0.0,0.52),(0.0017,0.29)]:
                p=2*math.pi*f*(1.0+detune+vib)*t
                voice+=weight*(math.sin(p)+0.26*math.sin(2*p)+0.08*math.sin(3*p))
            swell=min(1.0,t/1.0,(dur-t)/1.4)
            pad=voice*(0.028 if j else 0.036)*(0.80+0.20*math.sin(2*math.pi*0.085*t))*max(0,swell)
            l+=pad*(0.88 if j==1 else 1.0); r+=pad*(0.88 if j==0 else 1.0)
        # Warm brass-like harmonic layer enters during the second half of each phrase.
        brass_env=max(0.0,min(1.0,(local-1.0)/0.8))*max(0.0,min(1.0,(4.45-local)/0.8))
        for j,f in enumerate(chords[bar][:2]):
            p=2*math.pi*(f*2.0)*t
            brass=(math.sin(p)+0.45*math.sin(2*p)+0.22*math.sin(3*p))*brass_env*0.014
            l+=brass*(0.75 if j else 1.0); r+=brass*(1.0 if j else 0.75)
        # Harp-like arpeggio with stereo placement and a multi-partial pluck.
        step=int(t/0.28125); beat=t%0.28125
        f=chords[bar][(step+bar)%3]*2
        pluck=(math.sin(2*math.pi*f*beat)+0.32*math.sin(2*math.pi*f*2.01*beat)
               +0.10*math.sin(2*math.pi*f*3.98*beat))*math.exp(-beat*9.5)*0.060
        if step%2: l+=pluck; r+=pluck*0.42
        else: r+=pluck; l+=pluck*0.42
        # Lead bell/woodwind-like melody, with gentle breath envelope and harmonics.
        mstep=int(local/0.5625); mt=local%0.5625
        mf=melody[(bar*2+mstep)%len(melody)]
        attack=min(1.0,mt/0.035)
        bell=(math.sin(2*math.pi*mf*mt)+0.29*math.sin(2*math.pi*mf*2.76*mt)
              +0.11*math.sin(2*math.pi*mf*4.1*mt))*math.exp(-mt*3.5)*attack*0.043
        if mstep%2: r+=bell; l+=bell*0.62
        else: l+=bell; r+=bell*0.62
        # Low cinematic timpani pulse and soft frame-drum accents.
        beatpos=t%1.125
        freq=72-25*min(1.0,beatpos*4.0)
        kick=(math.sin(2*math.pi*freq*beatpos)+0.22*math.sin(2*math.pi*freq*2.1*beatpos))*math.exp(-beatpos*8.5)*0.052
        if beatpos<0.28: l+=kick; r+=kick
        # Quiet cymbal/shaker swell at each bar, panned for width.
        phrase=t%4.5
        if phrase<0.22:
            n=(random.random()*2-1)*math.exp(-phrase*13)*0.012
            l+=n; r-=n*0.72
        fade=min(1.0,t/1.25,(dur-t)/1.35)
        dry.append((math.tanh(l*1.75)*max(0.0,fade),math.tanh(r*1.75)*max(0.0,fade)))
    # Short stereo room tail, mixed from a few deterministic delayed taps.
    out=[]
    for i,(left,right) in enumerate(dry):
        tail_l=tail_r=0.0
        for delay,gain,swap in [(int(0.037*SR),0.11,False),(int(0.061*SR),0.075,True),(int(0.089*SR),0.045,False)]:
            j=i-delay
            if j>=0:
                tail_l+=dry[j][1 if swap else 0]*gain
                tail_r+=dry[j][0 if swap else 1]*gain
        out.append((math.tanh(left+tail_l),math.tanh(right+tail_r)))
    write_wav("kingdom_theme.wav",out)
def effect(name,kind):
    # Layered original sound design: transients, low-frequency impacts, harmonics, and stereo placement.
    d={"gather":0.62,"build":0.9,"train":1.05,"victory":1.8,"defeat":1.6,"scout":0.75}[kind]
    seq={"gather":[880,1320,1760],"build":[220,330,440],"train":[196,293.66,392],
         "victory":[392,493.88,587.33,783.99],"defeat":[392,311.13,233.08,174.61],
         "scout":[523.25,659.25,880]}[kind]
    samples=[]
    for i in range(int(SR*d)):
        t=i/SR; left=right=0.0
        # Musical layer: decaying partials with a short attack and slight pitch motion.
        for j,f in enumerate(seq):
            start=j*(d/(len(seq)+0.25)); u=t-start
            if u>=0:
                decay=math.exp(-u*(3.2 if kind in ("victory","defeat") else 7.5))
                attack=min(1.0,u/0.006)
                vibr=1.0+0.0035*math.sin(2*math.pi*5.1*t)
                tone=(math.sin(2*math.pi*f*vibr*u)+0.28*math.sin(2*math.pi*f*2.01*u)
                      +0.10*math.sin(2*math.pi*f*3.97*u))*decay*attack
                level=0.12 if kind in ("victory","defeat") else 0.095
                pan=0.28 if (j%2)==0 else 0.72
                left+=tone*level*(1.0-pan*0.42)
                right+=tone*level*(0.58+pan*0.42)
        # Short broadband transients make gather/build impacts less like UI beeps.
        if kind in ("gather","build","train","victory","defeat"):
            centers={"gather":[0.0,0.22],"build":[0.0,0.28,0.56],
                     "train":[0.0,0.36],"victory":[0.0,0.48,0.92],
                     "defeat":[0.0,0.55]}[kind]
            for j,center in enumerate(centers):
                u=t-center
                if 0.0<=u<0.18:
                    noise=(random.random()*2.0-1.0)
                    click=math.sin(2*math.pi*(1750.0-6200.0*u)*u)
                    low=math.sin(2*math.pi*(96.0-42.0*min(1.0,u*7.0))*u)
                    decay=math.exp(-u*(72.0 if kind in ("gather","build") else 28.0))
                    amount=0.16 if kind in ("build","defeat") else 0.10
                    hit=(noise*0.40+click*0.35+low*0.55)*decay*amount
                    left+=hit*(0.92 if j%2 else 1.0)
                    right+=hit*(1.0 if j%2 else 0.88)
        if kind=="scout":
            # Soft rising air/whoosh with a bell-like cue for expedition launch.
            fade=min(1.0,t/0.05)*max(0.0,min(1.0,(d-t)/0.14))
            air=(random.random()*2.0-1.0)*math.exp(-((t-0.22)/0.16)**2)*0.075
            whoosh=math.sin(2*math.pi*(180.0+460.0*t)*t)*fade*0.06
            left+=air+whoosh*0.72; right+=air*0.72+whoosh
        if kind=="build":
            # A short rasp underneath the hammer sequence suggests wood and stone work.
            rasp=(random.random()*2.0-1.0)*math.exp(-max(0.0,t-0.08)*5.0)*0.035 if t>0.08 else 0.0
            left+=rasp; right-=rasp*0.7
        # Fade boundaries and soft limiting prevent clicks or clipping in the exported master.
        fade=min(1.0,t/0.012,(d-t)/0.06)
        left=math.tanh(left*1.65)*max(0.0,fade)
        right=math.tanh(right*1.65)*max(0.0,fade)
        samples.append((left,right))
    # Extra cue-specific Foley-like layers are synthesized deterministically so each action
    # has a material identity even offline; these are sound-design effects, not field recordings.
    if kind=="gather":
        # Coin/ore clinks: inharmonic metallic partials with fast decay.
        for center,freq in [(0.035,1740),(0.19,2310),(0.37,1460)]:
            u=t-center
            if 0<=u<0.24:
                clink=(math.sin(2*math.pi*freq*u)+0.45*math.sin(2*math.pi*freq*2.73*u))*math.exp(-u*24)*0.055
                left+=clink; right+=clink*(0.65 if center==0.19 else 0.9)
    elif kind=="build":
        # Wood/stone hammer knocks: short filtered-noise burst and a low resonant body.
        for center in [0.12,0.34,0.58]:
            u=t-center
            if 0<=u<0.11:
                knock=((random.random()*2-1)*0.45+math.sin(2*math.pi*118*u))*math.exp(-u*42)*0.095
                left+=knock*(0.9 if center==0.34 else 1.0); right+=knock*0.88
    elif kind=="train":
        # Buckle/armor movement: several bright, quiet metal ticks under the training chime.
        for center,freq in [(0.09,2080),(0.22,1650),(0.43,2480)]:
            u=t-center
            if 0<=u<0.075:
                tick=(math.sin(2*math.pi*freq*u)+0.25*math.sin(2*math.pi*freq*1.6*u))*math.exp(-u*52)*0.045
                left+=tick; right+=tick*0.72
    elif kind in ("victory","defeat"):
        # Short shield/weapon impact with low thump and a metallic rattle.
        u=t-(0.18 if kind=="victory" else 0.32)
        if 0<=u<0.22:
            thump=math.sin(2*math.pi*(86-90*u)*u)*math.exp(-u*18)*0.08
            rattle=(random.random()*2-1)*math.exp(-u*38)*0.025
            left+=thump+rattle; right+=thump*0.92-rattle*0.55
    write_wav(name+".wav",samples)
music()
for k in ("gather","build","train","victory","defeat","scout"): effect(k,k)
print("APPTYA_ASSET_PIPELINE_AUDIO_SUCCESS")
