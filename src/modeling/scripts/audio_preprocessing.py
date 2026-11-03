"""Original CoordinateNet colored-noise augmentation; extracted without training entry."""
import numpy as np

def get_noise (nax, nlvl, bfreq, lowfr, upfr, upsgm, up2low, rng, SR):

    std = np.std (nax)

    nawhite = rng.standard_normal (nax.shape[0])
    naspwht = np.fft.rfft (nawhite)

    S = np.fft.rfftfreq (nax.shape[0])
    S[0] = 1.0e-08
    _Sl_ = np.where (S < 0.5*bfreq/16000, np.maximum (1-np.tanh (0.75*S/(0.5*bfreq/16000)), 0), 0) 
    _Sl_ = _Sl_ + np.where (S < 0.5*bfreq/16000, 0, (1 - np.tanh(0.75))/(S/(0.5*bfreq/16000)))

    _Sl_ = _Sl_/np.sqrt (np.mean(_Sl_**2))

    _lowfr_ = lowfr*0.5/(SR/2); _upfr_ = upfr*0.5/(SR/2)

    mu = rng.uniform (_lowfr_, _upfr_)
    sgm = 1000*0.5/(SR/2)*upsgm

    _Su_ = np.exp (-0.5*((S - mu)/sgm)**2) 
    
    _Su_ = _Su_/np.sqrt (np.mean(_Su_**2))

    S = _Sl_ + up2low*_Su_

#    S = S/np.sqrt (np.mean(S**2)) # Normalize S

    naspclr = naspwht * S
    nacolor = np.resize (np.fft.irfft (naspclr), nax.size)
    nacolor = nlvl*std*nacolor/np.sqrt (np.mean (nacolor**2))

    return nacolor

