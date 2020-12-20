import wiish/doctor
import ./build_ios
import ./build_android


proc checkDoctor*(): seq[DoctorResult] =
  result.add build_ios.checkDoctor()
  result.add build_android.checkDoctor()
