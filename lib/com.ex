defmodule Com do

  def test do
    # ComNerves.test()
  end


  def test1 do
    data = "head 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 89 0 6 3 1 1 1 1 1 1 1 1 1 1 1 1"
    ComLocal.start_cluster(
      data,
      &Exercise1.e1_split_function/2,
      &Exercise1.e1_function/1,
      &Exercise1.e1_merge_function/2
    )
  end

end
