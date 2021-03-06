
      subroutine damping (linnumber)
c******************************************************************************
c     This subroutine computes damping 'gamma' factors 
c     and then Voigt parameters 'a'
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'


      j = linnumber
      iwave = int(wave1(j)+0.0001)
      iatom = int(atom1(j)+0.0001)


c*****here is a totally empirical set of (large) damping parameters
c     for autoionization lines
      if (iatom.eq.20 .and. 
     .    (iwave.eq.6318 .or. iwave.eq.6343. or. iwave.eq.6361)) then
         if     (iwave .eq. 6318) then
            afactor = 20.
         elseif (iwave .eq. 6343) then
            afactor = 15.
         elseif (iwave .eq. 6361) then
            afactor = 28.
         endif
         do i=1,ntau
            a(j,i) = afactor
         enddo
         return
      endif


c*****for a few lines, explicit detailed broadening terms have 
c     appeared in the literature, and so do these lines with a 
c     sepaarate subroutine
      if (itru .eq. 1) then
         if (int(10*atom1(j)+0.01) .eq. 201) then
            if (iwave .eq. 8498 .or.
     .          iwave .eq. 8542 .or.
     .          iwave .eq. 8662) then
               call trudamp (j)
               damptype(j) = 'TRUEgam'
               return
            endif
         elseif (atom1(j) .eq. 20.0) then 
            if (iwave.eq.6717 .or. iwave.eq.6318) then
               call trudamp (j)
               damptype(j) = 'TRUEgam'
               return
            endif
         elseif (atom1(j) .eq. 11.0) then
               call trudamp (j)
               damptype(j) = 'TRUEgam'
               return
         endif
      endif
  

c*****here are the calculations to set up the damping; for atomic lines 
c     there are several options:
c        dampingopt = 0 and dampnum < 0 --->
c                             gammav = 10^{dampnum(i)}*(T/10000K)^0.3*n_HI
c        dampingopt = 0 and dampnum = 0 ---> 
c                             c6 = Unsold formula
c        dampingopt = 0 and dampnum > 10^(-10) ---> 
c                             c6 =  (Unsold formula)*dampnum(i)
c        dampingopt = 0 and dampnum(i) < 10^(-10) ---> 
c                             c6 = dampnum(i)
c        dampingopt = 1 --->    
c                             gammav = gamma_Barklem if possible, 
c                                        otherwise use dampingopt=0 options
c        dampingopt = 2 ---> 
c                             c6 = c6_Blackwell-group
c        dampingopt = 3 and dampnum <= 10^(-10) --->             
c                             c6 = c6_NEXTGEN for H I, He I, H2
c        dampingopt = 3 and dampnum > 10^(-10) --->             
c                             c6 = (c6_NEXTGEN for H I, He I, H2)*dampnum
c     for molecular lines (lacking a better idea) --->
c                                        c6 done as in dampingopt = 0


c*****these damping calculations are done at each atmosphere level
      if (linprintopt .gt. 2) write (nf1out,1001) j, wave1(j)
      do i=1,ntau
         ich = idint(charge(j) + 0.1)
         v1 = dsqrt(2.1175d8*t(i)*(1.0/amass(j)+1.008))


c*****first calculate an Unsold approximation to gamma_VanderWaals
         if (atom1(j) .gt. 100.) then
            ebreakup = 7.0
         else 
            ebreakup = chi(j,ich)
         endif
         if (e(j,1).ge.ebreakup .or. e(j,2).ge.ebreakup) then
            unsold = 1.0e-33
         else
            unsold = dabs(1.61d-33*(13.598*charge(j)/(ebreakup -
     .               e(j,1)))**2 - 1.61d-33*(13.598*charge(j)/
     .               (ebreakup-e(j,2)))**2)
         endif


c*****dampingopt = 0
         if     (dampingopt .eq. 0) then
            if     (dampnum(j) .lt. 0.0) then
               damptype(j) = 'MYgamma'
               gammav = 
     .            10.**dampnum(j)*(t(i)/10000.)**0.3*numdens(1,1,i)
            elseif (dampnum(j) .eq. 0.0) then
               damptype(j) = 'UNSLDc6'
               gammav = 17.0*unsold**0.4*v1**0.6*numdens(1,1,i)
            elseif (dampnum(j) .lt. 1.0d-10) then
               damptype(j) = '   MYc6'
               gammav = 17.0*dampnum(j)**0.4*v1**0.6*numdens(1,1,i)
            elseif (dampnum(j) .ge. 1.0d-10) then
               damptype(j) = 'MODUNc6'
               gammav = 
     .            17.0*(unsold*dampnum(j))**0.4*v1**0.6*numdens(1,1,i)
            endif


c*****dampingopt = 1
         elseif (dampingopt .eq. 1) then
            if (gambark(j) .gt. 0.) then
               damptype(j) = 'BKgamma'
               gammav = 
     .            gambark(j)*(t(i)/10000.)**alpbark(j)*numdens(1,1,i)
            else
               if     (dampnum(j) .lt. 0.0) then
                  damptype(j) = 'MYgamma'
                  gammav =
     .               10.**dampnum(j)*(t(i)/10000.)**0.3*numdens(1,1,i)
               elseif (dampnum(j) .eq. 0.0) then
                  damptype(j) = 'UNSLDc6'
                  gammav = 17.0*unsold**0.4*v1**0.6*numdens(1,1,i)
               elseif (dampnum(j) .lt. 1.0d-10) then
                  damptype(j) = '   MYc6'
                  gammav = 
     .               17.0*dampnum(j)**0.4*v1**0.6*numdens(1,1,i)
               elseif (dampnum(j) .ge. 1.0d-10) then
                  damptype(j) = 'MODUNc6'
                  gammav =
     .             17.0*(unsold*dampnum(j))**0.4*v1**0.6*numdens(1,1,i)
               endif
            endif


c*****dampingopt = 2
         elseif (dampingopt .eq. 2) then
            damptype(j) = 'BLKWLc6'
            gammav = 17.0*((1.0 + 0.67*e(j,1))*unsold)**0.4*
     .               v1**0.6*numdens(1,1,i)


c*****dampingopt = 3
         elseif (dampingopt .eq. 3) then
            damptype(j) = 'NXTGNc6'
            if (dampnum(j) .le. 1.0d-10) dampnum(j) = 1.0
                 c6h = dabs(1.01d-32*(charge(j)**2)*
     .              (13.598/(ebreakup - e(j,1)))**2 - 1.61d-33*
     .              (13.598/(ebreakup-e(j,2)))**2)
                 c6he = dabs((0.204956/0.666793)*1.01d-32*
     .                  (charge(j)**2)*(13.598/(ebreakup - 
     .                  e(j,1)))**2 - 1.61d-33*(13.598/(ebreakup-
     .                  e(j,2)))**2)
                 c6ht = dabs((0.806/0.666793)*1.01d-32*
     .                  (charge(j)**2)*(13.598/(ebreakup - 
     .                  e(j,1)))**2 - 1.61d-33*(13.598/(ebreakup-
     .                  e(j,2)))**2)
               gammav = 17.0*v1**0.6*(c6h**0.4*numdens(1,1,i) +
     .                  c6he**0.4*numdens(2,1,i) +
     .                  c6ht**0.4*numdens(8,1,i))*dampnum(j)**0.4
         endif

c*****now calculate radiative and Stark broadening (approximate formulae)
         gammar = 2.223d15/wave1(j)**2
         excdiff = chi(j,idint(charge(j)+0.001)) - e(j,2)
         if (excdiff .gt. 0.0 .and. atom1(j).lt.100.) then
            effn2 = 13.6*charge(j)**2/excdiff
         else
            effn2 = 25.
         endif
         gammas = 1.0e-8*ne(i)*effn2**2.5


c*****now finish by summing the gammas and computing the Voigt *a* values
         gammatot = gammar + gammas + gammav
         a(j,i) = gammatot*wave1(j)*1.0d-8/(12.56636*dopp(j,i))
         if (linprintopt .gt. 2) write (nf1out,1002) i, gammar, 
     .      gammas, gammav, gammatot, a(j,i)
      enddo
      return


c*****format statements
1001  format(//' LINE BROADENING PARAMETERS FOR LINE', i4,
     .       ' AT WAVELENGTH',f8.2/
     .       '  i',4x,'natural',6x,'Stark',4x,'VdWaals',
     .       6x,'total',5x,'a(j,i)')
1002  format (i3,1p5e11.3)


      end




