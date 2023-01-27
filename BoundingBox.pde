public class BoundingBox {
    public double minX;
    public double maxX;
    public double minY;
    public double maxY;

    public BoundingBox(List<Point> points) {
        minX = Double.MAX_VALUE;
        maxX = Double.MIN_VALUE;
        minY = Double.MAX_VALUE;
        maxY = Double.MIN_VALUE;

        for (Point point : points) {
            double x = point.x;
            double y = point.y;

            if (x < minX) {
                minX = x;
            }
            if (x > maxX) {
                maxX = x;
            }
            if (y < minY) {
                minY = y;
            }
            if (y > maxY) {
                maxY = y;
            }
        }
    }

}
