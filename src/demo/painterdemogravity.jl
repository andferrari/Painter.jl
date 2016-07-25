if(Pkg.installed("PyPlot") == nothing)
    Pkg.add("PyPlot")
end
using PyPlot

if !isfile("gravity/gravity_bc2016.oifits")
    if !isdir("gravity")
        mkdir("gravity")
    end
    download("http://www.opticalinterferometry.com/s/Object1-v3.oifits","gravity/gravity_bc2016.oifits")
end

function plotfunction(PDATA::PAINTER.PAINTER_Data,OIDATA::PAINTER.PAINTER_Input)
    nx = OIDATA.nx
    nw = OIDATA.nw
    wvl = OIDATA.wvl
    FOV = OIDATA.FOV
    x = PDATA.x
    w = PDATA.w
    if sum(w)==0
      w = 1.
    end
    indpix = linspace(-(FOV / 2), (FOV / 2), nx)
    pos = round(Int, [1, round(Int,nx / 4), round(Int,nx / 2), round(Int,nx * 3 / 4), nx])

    count_y = 0
    count_x = 0
    SubRow  = 5
    SubColumn = 5


    X3D = x .* max(0, w) .* max(x,0)
    VMIN = minimum(X3D)
    VMAX = maximum(X3D)

    figure("3D Image Reconstruction ")
    if nw == 250
      set = collect(1:10:250)
    elseif nw == 25
      set = collect(1:25)
    end
    n2 = 0
    for n in set
        n2+=1
        subplot(SubColumn, SubRow, n2)
        imshow( X3D[:, :, n]  , origin = "lower")#,vmin=VMIN,vmax=VMAX)
        titlestring = @sprintf("%2.4f µm", wvl[n2] * 1e6)
        title(titlestring)
        xticks([])
        yticks([])

        if( n2 == (length(set) + 1 - SubRow + count_x) )
            xticks(collect(pos - 1), round(Int,indpix[pos] * 1000) )
            xlabel("FOV (mas)")
            count_x += 1
        end
        if( n2 == (1 + count_y * SubRow))
            yticks(collect(pos - 1), round(Int,indpix[pos] * 1000) )
            ylabel("FOV (mas)")
            count_y += 1
        end
    end

    figure("Projection")

    subplot(223); imshow(squeeze(mean(X3D,1),1).',aspect="auto");
    xticks(collect(pos - 1), round(Int,indpix[pos] * 1000) )
    xlabel("FOV (mas)")
    ylabel("channels")
    title("spectrum 1")

    subplot(221); imshow(squeeze(mean(X3D,3),3), origin = "lower",aspect="auto");
    yticks(collect(pos - 1), round(Int,indpix[pos] * 1000) )
    xticks([])
    ylabel("FOV (mas)")
    title("Gray")

    subplot(222); imshow( squeeze(mean(X3D,2) ,2) , origin = "lower",aspect="auto");
    yticks([])
    xlabel("channels")
    title("Spectrum 2")

end
    # To change size of the simulation
    # nx pixels
    # files contains 250 wavelength, the set can be reduced to collect(1:10:250)
    # the plot function is done for 25 wavelengths
    # choose collect(1:10:250) or collect(1:250) or collect(1:25)
    nx = 64
    indwvl = collect(1:250) # will plot 1/10



    Folder = "gravity"
    savepath = "gravity_bc2016.jld"

    dptype = "phase"
    dpprm =  0

    CountPlot = 5
    nbitermax = 100

    aff = true
    admm = true

    PlotFct = plotfunction

    FOV = 0.06

    # rho_y = 10
    # rho_spat = .5
    # rho_ps = 0.1
    # rho_spec = .01

    rho_y = 10
    rho_spat = .1 #.5
    rho_ps = .1
    rho_spec = .5

    alpha = 1e3
    beta = 1e5

    lambda_spat =  1e-3 #1e-4
    lambda_spec = 0.1 #0.01
    lambda_L1 = 0.1

    epsilon = 1e-6

    eps1 = 1e-3
    eps2 = 1e-3

    xinit3D = []
    mask3D = PAINTER.mask(nx,round(Int, nx/2 - 2 ))

# initialize algorithm and run admm
    OIDATA, PDATA = PAINTER.painter(nbitermax = nbitermax, nx = nx, lambda_spat = lambda_spat,
                            lambda_spec = lambda_spec, rho_y = rho_y, rho_spat = rho_spat,
                            rho_spec = rho_spec, rho_ps = rho_ps, alpha = alpha, beta = beta,
                            eps1 = eps1, eps2 = eps2, FOV = FOV, indwvl = indwvl, admm = admm,
                            PlotFct = PlotFct, aff = aff, dptype = dptype, flux = 0,
                            dpprm = dpprm, Folder = Folder, lambda_L1=lambda_L1)

# save data struture in .jld files
    println("save results of gravity BC2016 data")
    PAINTER.paintersave(savepath,PDATA,OIDATA)

# load data struture in .jld files
    println("load results of gravity BC2016 data")
    PDATA, OIDATA = PAINTER.painterload(savepath)


    nothing
