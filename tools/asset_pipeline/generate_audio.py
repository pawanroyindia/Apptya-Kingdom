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
    dur=36.0; total=int(SR*dur); out=[]
    # Original modal fantasy theme: strings, bell-like plucks, bass, frame drum and layered harmony.
    chords=[(110.0,164.81,220.0),(98.0,146.83,196.0),(130.81,164.81,196.0),(87.31,130.81,174.61),
            (110.0,164.81,220.0),(130.81,196.0,261.63),(98.0,146.83,196.0),(82.41,123.47,164.81)]
    melody=[440,392,329.63,293.66,329.63,392,440,523.25,493.88,440,392,329.63,293.66,329.63,392,440]
    for i in range(total):
        t=i/SR; bar=int(t/4.5)%len(chords); local=t%4.5
        l=r=0.0
        for j,f in enumerate(chords[bar]):
            phase=2*math.pi*f*t
            # Warm sustained bowed tone with slow vibrato and upper harmonics.
            tone=(math.sin(phase+0.12*math.sin(2*math.pi*4.3*t))+
                  0.38*math.sin(2*phase)+0.13*math.sin(3*phase))
            pad=tone*(0.042 if j else 0.055)*(0.82+0.18*math.sin(2*math.pi*0.11*t))
            l+=pad*(0.8 if j==1 else 1.0); r+=pad*(0.8 if j==0 else 1.0)
        # Arpeggiated plucked strings, stereo alternation and natural decay.
        step=int(t/0.375); beat=t%0.375
        f=chords[bar][(step+bar)%3]*2
        pluck=(math.sin(2*math.pi*f*beat)+0.42*math.sin(2*math.pi*f*2.01*beat))*math.exp(-beat*8.5)*0.095
        if step%2: l+=pluck; r+=pluck*0.55
        else: r+=pluck; l+=pluck*0.55
        # Lead phrase every half bar, with a soft bell attack and decaying partials.
        mstep=int(local/0.5625); mt=local%0.5625
        mf=melody[(bar*2+mstep)%len(melody)]
        bell=(math.sin(2*math.pi*mf*mt)+0.35*math.sin(2*math.pi*mf*2.76*mt)+0.14*math.sin(2*math.pi*mf*4.1*mt))*math.exp(-mt*4.2)*0.052
        if mstep%2: r+=bell; l+=bell*0.68
        else: l+=bell; r+=bell*0.68
        # Low cinematic pulse and quiet frame-drum transients on the beat.
        beatpos=t%1.125
        kick=math.sin(2*math.pi*(72-28*min(1,beatpos*5))*beatpos)*math.exp(-beatpos*11)*0.075
        if beatpos<0.25: l+=kick; r+=kick
        # Soft cymbal/shaker texture only at phrase accents.
        phrase=t%4.5
        if phrase<0.045:
            n=(random.random()*2-1)*math.exp(-phrase*70)*0.022
            l+=n; r-=n*0.7
        # Smooth fade-in/out and conservative peak level.
        fade=min(1,t/1.4,(dur-t)/1.2)
        out.append((math.tanh(l*1.8)*fade,math.tanh(r*1.8)*fade))
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
    write_wav(name+".wav",samples)
music()
for k in ("gather","build","train","victory","defeat","scout"): effect(k,k)
print("APPTYA_ASSET_PIPELINE_AUDIO_SUCCESS")
