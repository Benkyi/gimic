!
! Write Gaussian type cube files
!
module cubeplot_module
    use globals_module
    use settings_module
    use grid_class
    implicit none

contains
    subroutine write_cubeplot(fname, grid, pdata, skip)
        character(*), intent(in) :: fname
        type(grid_t) :: grid
        real(DP), dimension(:,:,:) :: pdata
        integer(I4), optional :: skip

        integer(I4) :: skp=1
        integer(I4) :: i,j,k,l, fd
        integer(I4), dimension(3) :: npts
        real(DP), dimension(2) :: qrange
        real(DP), dimension(3) :: qmin, qmax, step

        call getfd(fd)
        open(fd,file=trim(fname),form='formatted',status='unknown')
        write(fd,*) 'Gaussian cube data, generated by genpot'
        write(fd,*) 

        call get_grid_size(grid, npts(1), npts(2), npts(3))

! This only works for equidistant grids. Non-equidistant grids should be
! flagged in grid.f90 and interpolated. grid.f90 should be reworked, big time.
        qmin=gridpoint(grid,1,1,1)
        qmax=gridpoint(grid,npts(1),npts(2),npts(3))
        step=(qmax-qmin)/(npts-1)

        write(fd, '(i5,3f12.6)') 0, qmin
        write(fd, '(i5,3f12.6)') npts(1), step(1), 0.d0, 0.d0
        write(fd, '(i5,3f12.6)') npts(2), 0.d0, step(2), 0.d0
        write(fd, '(i5,3f12.6)') npts(3), 0.d0, 0.d0, step(3)
!        write(fd, '(i5,4f12.6)') 0, 0.d0, 0.d0, 0.d0, 0.d0

        l=0
        do i=1,npts(1)
            do j=1,npts(2)
                do k=1,npts(3)
                    write(fd,'(f12.6)',advance='no') pdata(i,j,k)
                    if (mod(l,6) == 5) write(fd,*)
                    l=l+1
                end do
            end do
        end do

        call closefd(fd)

    end subroutine
end module

! vim:et:sw=4:ts=4
